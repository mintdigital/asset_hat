require 'rake/testtask'
require 'active_support'
require 'action_controller'
require 'action_view'
require File.join(File.dirname(__FILE__), %w[.. asset_hat])



unless defined?(RAILS_ROOT)
  RAILS_ROOT = File.join(File.dirname(__FILE__), '..', '..')
end

task :default => :test

desc 'Run tests'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib' << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = false
end

desc 'Empty test; allows Rails tasks to span multiple files'
task :environment do
end



namespace :asset_hat do
  desc 'Minifies all CSS and JS bundles'
  task :minify do
    Rake::Task['asset_hat:css:minify'].invoke # Generate all CSS bundles
    Rake::Task['asset_hat:js:minify'].invoke  # Generate all JS bundles
  end

  namespace :locales do
    desc 'Generates locale-specific assets for all locales'
    task :generate, :host, :needs => :environment do |t, args|
      args.with_defaults :host => 'http://localhost:3000'
      locales = COUNTRY_LOCALES.keys.map(&:to_s)

      locales.each do |locale|
        puts `rake asset_hat:locales:generate_for[#{args.host},#{locale}]`
          # Doesn't work with `Rake::Task[...].invoke`
      end
    end # task :generate

    desc 'Generates locale-specific assets for one given locale'
    task :generate_for, :host, :locale, :needs => :environment do |t, args|
      unless args.host.present? && args.locale.present?
        raise 'Usage: rake asset_hat:locales:generate_for[host,locale]' and return
      end

      require 'action_controller/integration'
      app = ActionController::Integration::Session.new
      app.host! args.host

      # Generate i18n.LOCALE.min.js
      request_path    = "/javascripts/i18n.#{args.locale}.js"
      target_filepath = AssetHat::min_filepath(
        File.join(%w[public javascripts locales], args.locale, 'i18n.js'), 'js')
      begin
        FileUtils.makedirs(File.dirname(target_filepath))
        app.get request_path
        output = AssetHat::JS::minify(app.response.body)
        File.open(target_filepath, 'w') { |f| f.write output }
        puts "- Generated #{target_filepath}"
      rescue Exception => e
        puts "Could not write file: #{target_filepath}"
        puts "- #{e}"
      end
    end # task :generate_for

  end # namespace :locales

  namespace :css do
    desc 'Adds mtimes to asset URLs in CSS'
    task :add_asset_mtimes, :filename, :verbose do |t, args|
      unless args.filename.present?
        raise 'Usage: rake asset_hat:css:add_asset_mtimes[filename.css]' and return
      end

      args.with_defaults :verbose => true

      css = File.open(args.filename, 'r') { |f| f.read }
      css = AssetHat::CSS::add_asset_mtimes(css)
      File.open(args.filename, 'w') { |f| f.write css }

      puts "- Added asset mtimes to #{args.filename}" if args.verbose
    end

    desc 'Adds hosts to asset URLs in CSS'
    task :add_asset_hosts, :filename, :verbose, :needs => :environment do |t, args|
      unless args.filename.present?
        raise 'Usage: rake asset_hat:css:add_asset_hosts[filename.css]' and return
      end

      args.with_defaults :verbose => true

      asset_host = ActionController::Base.asset_host
      if asset_host.blank?
        raise "This environment (#{ENV['RAILS_ENV']}) doesn't have an `asset_host` configured."
        return
      end

      css = File.open(args.filename, 'r') { |f| f.read }
      css = AssetHat::CSS::add_asset_hosts(css, asset_host)
      File.open(args.filename, 'w') { |f| f.write css }

      puts "- Added asset hosts to #{args.filename}" if args.verbose
    end

    desc 'Minifies one CSS file'
    task :minify_file, :filepath, :verbose do |t, args|
      unless args.filepath.present?
        raise 'Usage: rake asset_hat:css:minify_file[path/to/filename.css]' and return
      end

      args.with_defaults :verbose => false

      input   = File.open(args.filepath, 'r').read
      output  = AssetHat::CSS::minify(input)

      # Write minified content to file
      target_filepath = AssetHat::CSS::min_filepath(args.filepath)
      File.open(target_filepath, 'w') { |f| f.write output }

      # Print results
      puts "- Minified to #{target_filepath}" if args.verbose
    end

    desc 'Minifies one CSS bundle'
    task :minify_bundle, :bundle, :needs => :environment do |t, args|
      unless args.bundle.present?
        raise 'Usage: rake asset_hat:css:minify_bundle[application]' and return
      end

      config = AssetHat::config
      old_bundle_size = 0.0
      new_bundle_size = 0.0

      # Get bundle filenames
      filenames = config['css']['bundles'][args.bundle]
      if filenames.empty?
        raise "No CSS files are specified for the #{args.bundle} bundle in #{AssetHat::CONFIG_FILEPATH}."
        return
      end
      filepaths = filenames.map do |filename|
        File.join('public', 'stylesheets', "#{filename}.css")
      end
      bundle_filepath = AssetHat::CSS::min_filepath(File.join(
        'public', 'stylesheets', 'bundles', "#{args.bundle}.css"))

      # Concatenate and process output
      output = ''
      asset_host = ActionController::Base.asset_host
      filepaths.each do |filepath|
        file_output = File.open(filepath, 'r').read
        old_bundle_size += file_output.size

        file_output = AssetHat::CSS::minify(file_output)
        file_output = AssetHat::CSS::add_asset_mtimes(file_output)
        if asset_host.present?
          file_output = AssetHat::CSS::add_asset_hosts(file_output, asset_host)
        end

        new_bundle_size += file_output.size
        output << file_output + "\n"
      end
      FileUtils.makedirs(File.dirname(bundle_filepath))
      File.open(bundle_filepath, 'w') { |f| f.write output }

      # Print results
      percent_saved = 1 - (new_bundle_size / old_bundle_size)
      puts "\nWrote CSS bundle: #{bundle_filepath}"
      filepaths.each do |filepath|
        puts "        contains: #{filepath}"
      end
      if old_bundle_size > 0
        puts "        MINIFIED: #{'%.1f' % (percent_saved * 100)}%"
      end
    end

    desc 'Concatenates and minifies all CSS bundles'
    task :minify do
      # Get input bundles
      config = AssetHat::config
      bundles = config['css']['bundles'].keys

      # Minify bundles
      bundles.each do |bundle|
        Rake::Task['asset_hat:css:minify_bundle'].reenable
        Rake::Task['asset_hat:css:minify_bundle'].invoke(bundle)
      end
    end

  end # namespace :css

  namespace :js do
    desc 'Minifies one JS file'
    task :minify_file, :filepath, :verbose do |t, args|
      unless args.filepath.present?
        raise 'Usage: rake asset_hat:js:minify_file[filepath.js]' and return
      end

      args.with_defaults :verbose => false

      if args.verbose && args.filepath.match(/\.min\.js$/)
        puts "#{args.filepath} is already minified."
        exit 1
      end

      input   = File.open(args.filepath, 'r').read
      output  = AssetHat::JS::minify(input)

      # Write minified content to file
      target_filepath = AssetHat::JS::min_filepath(args.filepath)
      File.open(target_filepath, 'w') { |f| f.write output }

      # Print results
      puts "- Minified to #{target_filepath}" if args.verbose
    end

    desc 'Minifies one JS bundle'
    task :minify_bundle, :bundle do |t, args|
      unless args.bundle.present?
        raise 'Usage: rake asset_hat:js:minify_bundle[application]' and return
      end

      config = AssetHat::config
      old_bundle_size = 0.0
      new_bundle_size = 0.0

      # Get bundle filenames
      filenames = config['js']['bundles'][args.bundle]
      if filenames.empty?
        raise "No JS files are specified for the #{args.bundle} bundle in #{AssetHat::CONFIG_FILEPATH}."
        return
      end
      filepaths = filenames.map do |filename|
        File.join('public', 'javascripts', "#{filename}.js")
      end
      bundle_filepath = AssetHat::JS::min_filepath(File.join(
        'public', 'javascripts', 'bundles', "#{args.bundle}.js"))

      # Concatenate and process output
      output = ''
      filepaths.each do |filepath|
        file_output = File.open(filepath, 'r').read
        old_bundle_size += file_output.size
        unless filepath =~ /\.min\.js$/ # Already minified
          file_output = AssetHat::JS::minify(file_output)
        end
        new_bundle_size += file_output.size
        output << file_output + "\n"
      end
      FileUtils.makedirs(File.dirname(bundle_filepath))
      File.open(bundle_filepath, 'w') { |f| f.write output }

      # Print results
      percent_saved = 1 - (new_bundle_size / old_bundle_size)
      puts "\n Wrote JS bundle: #{bundle_filepath}"
      filepaths.each do |filepath|
        puts "        contains: #{filepath}"
      end
      if old_bundle_size > 0
        puts "        MINIFIED: #{'%.1f' % (percent_saved * 100)}%"
      end
    end

    desc 'Concatenates and minifies all JS bundles'
    task :minify do
      # Get input bundles
      config = AssetHat::config
      bundles = config['js']['bundles'].keys

      # Minify bundles
      bundles.each do |bundle|
        Rake::Task['asset_hat:js:minify_bundle'].reenable
        Rake::Task['asset_hat:js:minify_bundle'].invoke(bundle)
      end
    end

  end # namespace :js

end # namespace :asset_hat

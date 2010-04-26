namespace :asset_hat do
  namespace :js do

    desc 'Minifies one JS file'
    task :minify_file, :filepath, :verbose, :needs => :environment do |t, args|
      if args.filepath.blank?
        raise 'Usage: rake asset_hat:js:minify_file[filepath.js]' and return
      end

      args.with_defaults :verbose => false
      min_options = {
        :engine => AssetHat.config['js']['engine']
      }.reject { |k,v| v.blank? }

      if args.verbose && args.filepath.match(/\.min\.js$/)
        puts "#{args.filepath} is already minified."
        exit 1
      end

      input   = File.open(args.filepath, 'r').read
      output  = AssetHat::JS.minify(input, min_options)

      # Write minified content to file
      target_filepath = AssetHat::JS.min_filepath(args.filepath)
      File.open(target_filepath, 'w') { |f| f.write output }

      # Print results
      puts "- Minified to #{target_filepath}" if args.verbose
    end

    desc 'Minifies one JS bundle'
    task :minify_bundle, :bundle, :needs => :environment do |t, args|
      if args.bundle.blank?
        raise 'Usage: rake asset_hat:js:minify_bundle[application]' and return
      end

      config = AssetHat.config
      old_bundle_size = 0.0
      new_bundle_size = 0.0
      min_options = {
        :engine => config['js']['engine']
      }.reject { |k,v| v.blank? }

      # Get bundle filenames
      filenames = config['js']['bundles'][args.bundle]
      if filenames.empty?
        raise "No JS files are specified for the #{args.bundle} bundle in #{AssetHat::CONFIG_FILEPATH}."
        return
      end
      filepaths = filenames.map do |filename|
        File.join('public', 'javascripts', "#{filename}.js")
      end
      bundle_filepath = AssetHat::JS.min_filepath(File.join(
        'public', 'javascripts', 'bundles', "#{args.bundle}.js"))

      # Concatenate and process output
      output = ''
      filepaths.each do |filepath|
        file_output = File.open(filepath, 'r').read
        old_bundle_size += file_output.size
        unless filepath =~ /\.min\.js$/ # Already minified
          file_output = AssetHat::JS.minify(file_output, min_options)
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
        engine = "(Engine: #{min_options[:engine]})"
        puts "        MINIFIED: #{'%.1f' % (percent_saved * 100)}% #{engine}"
      end
    end

    desc 'Concatenates and minifies all JS bundles'
    task :minify, :needs => :environment do
      # Get input bundles
      config = AssetHat.config
      if config['js'].blank? || config['js']['bundles'].blank?
        puts "You need to set up JS bundles in #{AssetHat::CONFIG_FILEPATH}."
        exit
      end
      bundles = config['js']['bundles'].keys

      # Minify bundles
      bundles.each do |bundle|
        Rake::Task['asset_hat:js:minify_bundle'].reenable
        Rake::Task['asset_hat:js:minify_bundle'].invoke(bundle)
      end
    end

  end # namespace :js
end # namespace :asset_hat

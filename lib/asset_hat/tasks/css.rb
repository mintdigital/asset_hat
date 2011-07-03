namespace :asset_hat do
  namespace :css do

    desc 'Adds commit IDs to asset URLs in CSS for cache busting'
    task :add_asset_commit_ids, [:filename] => :environment do |t, args|
      if args.filename.blank?
        raise 'Usage: rake asset_hat:css:' +
          'add_asset_commit_ids[filename.css]' and return
      end

      verbose = (ENV['VERBOSE'] != 'false') # Defaults to `true`

      css = File.open(args.filename, 'r') { |f| f.read }
      css = AssetHat::CSS.add_asset_commit_ids(css)
      File.open(args.filename, 'w') { |f| f.write css }

      puts "- Added asset commit IDs to #{args.filename}" if verbose
    end

    desc 'Adds hosts to asset URLs in CSS'
    task :add_asset_hosts, [:filename] => :environment do |t, args|
      if args.filename.blank?
        raise 'Usage: rake asset_hat:css:' +
          'add_asset_hosts[filename.css]' and return
      end

      verbose = (ENV['VERBOSE'] != 'false') # Defaults to `true`

      asset_host = ActionController::Base.asset_host
      if asset_host.blank?
        raise "This environment (#{ENV['RAILS_ENV']}) " +
          "doesn't have an `asset_host` configured." and return
      end

      css = File.open(args.filename, 'r') { |f| f.read }
      css = AssetHat::CSS.add_asset_hosts(css, asset_host)
      File.open(args.filename, 'w') { |f| f.write css }

      puts "- Added asset hosts to #{args.filename}" if verbose
    end

    desc 'Minifies one CSS file'
    task :minify_file, [:filepath] => :environment do |t, args|
      type = 'css'

      if args.filepath.blank?
        raise "Usage: rake asset_hat:#{type}:" +
          "minify_file[path/to/filename.#{type}]" and return
      end

      verbose = (ENV['VERBOSE'] != 'false') # Defaults to `true`
      min_options = {
        :engine => AssetHat.config[type]['engine']
      }.reject { |k,v| v.blank? }

      input   = File.open(args.filepath, 'r').read
      output  = AssetHat::CSS.minify(input, min_options)

      # Write minified content to file
      target_filepath = AssetHat::CSS.min_filepath(args.filepath)
      File.open(target_filepath, 'w') { |f| f.write output }

      # Print results
      puts "- Minified to #{target_filepath}" if verbose
    end

    desc 'Minifies one CSS bundle'
    task :minify_bundle, [:bundle] => :environment do |t, args|
      type = 'css'

      if args.bundle.blank?
        raise "Usage: rake asset_hat:#{type}:" +
          "minify_bundle[application]" and return
      end

      config = AssetHat.config[type]
      report_format = ([ENV['FORMAT']] & %w[long short dot])[0] || 'long'
      $stdout.sync  = (report_format == 'dot')
      min_options = {
        :engine => config['engine']
      }.reject { |k,v| v.blank? }

      # Get bundle filenames
      filenames = config['bundles'][args.bundle].select(&:present?)
      if filenames.empty?
        raise "No #{type.upcase} files are specified for the " +
          "#{args.bundle} bundle in #{AssetHat::CONFIG_FILEPATH}." and return
      end
      filepaths = filenames.map do |filename|
        parts = filename.split(File::SEPARATOR)
        parts.last << '.' << type unless parts.last =~ /\.#{type}$/
        File.join(
          (parts.first.present? ?
            AssetHat.assets_dir(type) : # Given path was relative
            AssetHat::ASSETS_DIR),      # Given path was absolute
          parts
        )
      end

      # Check whether app has special SSL asset host
      asset_host = ActionController::Base.asset_host
      output_options_array = [{:ssl => false}]
      if AssetHat.ssl_asset_host_differs?
        # The bundle needs a second version, which uses the asset host via SSL
        output_options_array << {:ssl => true}
      end

      output_options_array.each do |output_options|

        # Concatenate and process output
        bundle_filepath = AssetHat::CSS.min_filepath(File.join(
          AssetHat.bundles_dir(type, output_options.slice(:ssl)),
          "#{args.bundle}.#{type}"))
        old_bundle_size = 0.0
        new_bundle_size = 0.0
        output     = ''
        filepaths.each do |filepath|
          file_output = File.open(filepath, 'r').read
          old_bundle_size += file_output.size

          file_output = AssetHat::CSS.minify(file_output, min_options)
          file_output = AssetHat::CSS.add_asset_commit_ids(file_output)
          if asset_host.present?
            file_output = AssetHat::CSS.add_asset_hosts(
              file_output, asset_host, output_options.slice(:ssl))
          end

          new_bundle_size += file_output.size
          output << file_output + "\n"
        end
        FileUtils.makedirs(File.dirname(bundle_filepath))
        File.open(bundle_filepath, 'w') { |f| f.write output }

        # Print results
        percent_saved =
          "#{'%.1f' % ((1 - (new_bundle_size / old_bundle_size)) * 100)}%"
        bundle_filepath.sub!(/^#{Rails.root}\//, '')
        case report_format
        when 'dot'
          print '.'
        when 'short'
          puts "Minified #{percent_saved.rjust(6)}: #{bundle_filepath}"
        else # 'long'
          puts "\nWrote #{type.upcase} bundle: #{bundle_filepath}"
          filepaths.each do |filepath|
            puts "        contains: #{filepath.sub(/^#{Rails.root}\//, '')}"
          end
          if old_bundle_size > 0
            puts "        MINIFIED: #{percent_saved}" +
                          (" (empty!)" if new_bundle_size == 0).to_s +
                          " (Engine: #{min_options[:engine]})"
          end
        end
      end
    end

    desc 'Concatenates and minifies all CSS bundles'
    task :minify, [:opts] => :environment do |t, args|
      args.with_defaults(:opts => {})
      opts = args.opts.reverse_merge(:show_intro => true, :show_outro => true)
      type = 'css'
      report_format = ENV['FORMAT']

      if opts[:show_intro]
        print "Minifying #{type.upcase}..."
        if report_format == 'dot'
          $stdout.sync = true # Output immediately
        else
          puts
        end
      end

      # Get input bundles
      config = AssetHat.config[type]
      if config.blank? || config['bundles'].blank?
        raise "You need to set up #{type.upcase} bundles " +
          "in #{AssetHat::CONFIG_FILEPATH}." and return
      end
      bundles = config['bundles'].keys

      # Minify bundles
      bundles.each do |bundle|
        task = Rake::Task["asset_hat:#{type}:minify_bundle"]
        task.reenable
        task.invoke(bundle)
      end

      if opts[:show_outro]
        puts unless report_format == 'short'
        puts 'Done.'
      end
    end

  end # namespace :css
end # namespace :asset_hat

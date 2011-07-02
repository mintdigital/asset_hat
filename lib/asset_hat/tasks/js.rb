namespace :asset_hat do
  namespace :js do

    desc 'Minifies one JS file'
    task :minify_file, [:filepath] => :environment do |t, args|
      type = 'js'

      if args.filepath.blank?
        raise "Usage: rake asset_hat:#{type}:" +
          "minify_file[filepath.#{type}]" and return
      end

      verbose = (ENV['VERBOSE'] != 'false') # Defaults to `true`
      min_options = {
        :engine => AssetHat.config[type]['engine']
      }.reject { |k,v| v.blank? }

      if verbose && args.filepath.match(/\.min\.#{type}$/)
        raise "#{args.filepath} is already minified." and return
      end

      input   = File.open(args.filepath, 'r').read
      output  = AssetHat::JS.minify(input, min_options)

      # Write minified content to file
      target_filepath = AssetHat::JS.min_filepath(args.filepath)
      File.open(target_filepath, 'w') { |f| f.write output }

      # Print results
      puts "- Minified to #{target_filepath}" if verbose
    end

    desc 'Minifies one JS bundle'
    task :minify_bundle, [:bundle] => :environment do |t, args|
      type = 'js'

      if args.bundle.blank?
        raise "Usage: rake asset_hat:#{type}:" +
          "minify_bundle[application]" and return
      end

      config = AssetHat.config[type]
      report_format = ([ENV['FORMAT']] & %w[long short dot])[0] || 'long'
      $stdout.sync = true if report_format == 'dot' # Output immediately
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
      bundle_filepath = AssetHat::JS.min_filepath(File.join(
        AssetHat.bundles_dir(type), "#{args.bundle}.#{type}"))

      # Concatenate and process output
      output = ''
      old_bundle_size = 0.0
      new_bundle_size = 0.0
      filepaths.each do |filepath|
        file_output = File.open(filepath, 'r').read
        old_bundle_size += file_output.size
        unless filepath =~ /\.min\.#{type}$/ # Already minified
          file_output = AssetHat::JS.minify(file_output, min_options)
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
        puts "\n Wrote #{type.upcase} bundle: #{bundle_filepath}"
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

    desc 'Concatenates and minifies all JS bundles'
    task :minify, [:opts] => :environment do |t, args|
      args.with_defaults(:opts => {})
      opts = args.opts.reverse_merge(:show_intro => true, :show_outro => true)
      type = 'js'
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

  end # namespace :js
end # namespace :asset_hat

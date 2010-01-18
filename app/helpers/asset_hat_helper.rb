module AssetHatHelper
  unless defined?(RAILS_ROOT)
    RAILS_ROOT = File.join(File.dirname(__FILE__), '..', '..')
  end

  def include_assets(type, *args)
    # `include_css` and `include_js` are recommended instead.

    type = type.to_sym
    allowed_types = AssetHat::TYPES
    unless allowed_types.include?(type)
      expected_types = allowed_types.map { |x| ":#{x}" }.to_sentence(
        :two_words_connector => ' or ',
        :last_word_connector => ', or '
      )
      raise "Unknown type :#{type}; should be #{expected_types}"
      return
    end

    options = args.extract_options!
    options.symbolize_keys!
    options.reverse_merge!(:media => 'screen,projection') if type == :css

    filenames = []
    sources   = [] # The URLs that are ultimately included via HTML
    source_commit_ids = {} # Last commit ID for each source

    # Set to `true` to use bundles and minified code:
    use_caching = AssetHat.cache?
    use_caching = options[:cache] unless options[:cache].nil?
    options.delete :cache # Completely avoid Rails' built-in caching

    if options[:bundle].present? || options[:bundles].present?
      bundles = [options.delete(:bundle), options.delete(:bundles)].
                  flatten.reject(&:blank?)
      if use_caching
        sources += bundles.map { |b| "bundles/#{b}.min.#{type}" }
      else
        config = AssetHat.config
        filenames = bundles.map { |b| AssetHat.bundle_filenames(b, type) }.
                      flatten.reject(&:blank?)
      end
    else
      filenames = args
    end

    filenames.each do |filename|
      if filename.match(/\.#{type}$/)
        sources << filename
      else
        min_filename_with_ext = "#{filename}.min.#{type}"
        if use_caching && AssetHat.asset_exists?(min_filename_with_ext, type)
          sources << min_filename_with_ext  # Use minified version
        else
          sources << "#{filename}.#{type}"  # Use original version
        end
      end
    end

    sources.uniq!

    if use_caching
      # Add commit IDs to bust browser caches based on when each file was
      # last updated in the repository. If `use_caching` is false (e.g., in
      # development environments), skip this, and instead default to Rails'
      # mtime-based cache busting.
      sources.map! do |src|
        if src =~ /^bundles\//
          # Get commit ID of bundle file with most recently committed update
          bundle = src.match(/^bundles\/(.*)\.min\.#{type}$/)[1]
          commit_id = AssetHat.last_bundle_commit_id(bundle, type)
        else
          # Get commit ID of file's most recently committed update
          commit_id = AssetHat.last_commit_id(
            File.join(AssetHat.assets_dir(type), src))
        end
        if commit_id.present? # False if file isn't committed to repo
          src += "#{src =~ /\?/ ? '&' : '?'}#{commit_id}"
        end
        src
      end
    end

    # Build output HTML
    sources.map do |src|
      case type
      when :css
        stylesheet_link_tag(src, options)
      when :js
        javascript_include_tag(src, options)
      end
    end.join("\n")
  end

  def include_css(*args)
    # Usage:
    #
    # Include a single stylesheet:
    #   include_css 'diagnostics'
    #   =>  <link href="/stylesheets/diagnostics.min.css" media="screen,projection" rel="stylesheet" type="text/css" />
    #
    # Include a single unminified stylesheet:
    #   include_css 'diagnostics.css'
    #   =>  <link href="/stylesheets/diagnostics.css" media="screen,projection" rel="stylesheet" type="text/css" />
    #
    # Include a bundle of stylesheets (i.e., a concatenated set of
    # stylesheets; configure in config/assets.yml):
    #   include_css :bundle => 'application'
    #   =>  <link href="/stylesheets/bundles/application.min.css" ... />
    #
    # Include multiple stylesheets separately (not as cool):
    #   include_css 'reset', 'application', 'clearfix'
    #   =>  <link href="/stylesheets/reset.min.css" ... />
    #       <link href="/stylesheets/application.min.css" ... />
    #       <link href="/stylesheets/clearfix.min.css" ... />

    return if args.blank?
    include_assets :css, *args
  end

  def include_js(*args)
    # Usage:
    #
    # Include a single JS file:
    #   include_js 'application'
    #   =>  <script src="/javascripts/application.min.js" type="text/javascript"></script>
    #
    # Include a single JS unminified file:
    #   include_js 'application.js'
    #   =>  <script src="/javascripts/application.js" type="text/javascript"></script>
    #
    # Include jQuery:
    #   include_js :jquery  # Development/test environment
    #   =>  <script src="/javascripts/jquery-VERSION.min.js" ...></script>
    #   include_js :jquery  # Staging/production environment
    #   =>  <script src="http://ajax.googleapis.com/.../jquery.min.js" ...></script>
    #     # Set jQuery versions either in `config/assets.yml`, or by using
    #     # `include_js :jquery, :version => '1.4'`.
    #
    # Include a bundle of JS files (i.e., a concatenated set of files;
    # configure in config/assets.yml):
    #   include_js :bundle => 'application'
    #   =>  <script src="/javascripts/bundles/application.min.js" ...></script>
    #
    # Include multiple bundles of JS files:
    #   include_js :bundles => %w[plugins common]
    #   =>  <script src="/javascripts/bundles/plugins.min.js" ...></script>
    #       <script src="/javascripts/bundles/common.min.js" ...></script>
    #
    # Include multiple JS files separately (not as cool):
    #   include_js 'bloombox', 'jquery.cookie', 'jquery.json.min'
    #   =>  <script src="/javascripts/bloombox.min.js" ...></script>
    #       <script src="/javascripts/jquery.cookie.min.js" ...></script>
    #       <script src="/javascripts/jquery.json.min.js" ...></script>

    return if args.blank?
    html = []
    options = args.extract_options!

    included_vendors = (args & AssetHat::JS::VENDORS)
    included_vendors.each do |vendor|
      args.delete vendor
      source = AssetHat::JS::Vendors.source_for(vendor, options.slice(:version))
      html << include_assets(:js, source, :cache => true)
    end

    html << include_assets(:js, *(args + [options]))
    html.join("\n").strip
  end

end

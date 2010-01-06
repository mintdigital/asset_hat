module AssetHatHelper
  unless defined?(RAILS_ROOT)
    RAILS_ROOT = File.join(File.dirname(__FILE__), '..', '..')
  end

  def include_assets(type, *args)
    # `include_css` and `include_js` are recommended instead.

    allowed_types = [:css, :js]
    unless allowed_types.include?(type)
      expected_types = allowed_types.map { |x| ":#{x}" }.to_sentence(
        :two_words_connector => ' or ',
        :last_word_connector => ', or '
      )
      raise "Unknown type :#{klass}; should be #{expected_types}"
      return
    end

    options = args.extract_options!
    options.symbolize_keys!
    options.reverse_merge!(:media => 'screen,projection') if type == :css

    filenames   = []
    sources     = []
    assets_dir  = (type == :css ? 'stylesheets' : 'javascripts')

    # Set to `true` to use bundles and minified code:
    use_caching = ActionController::Base.perform_caching
    use_caching = options[:cache] unless options[:cache].nil?

    if options[:bundle].present? || options[:bundles].present?
      bundles = [options.delete(:bundle), options.delete(:bundles)].
                  compact.flatten.reject(&:blank?)
      if use_caching
        sources += bundles.map { |b| "bundles/#{b}.min.#{type}" }
      else
        config_filename = File.join(RAILS_ROOT, 'config', 'assets.yml')
        config = YAML::load(File.open(config_filename, 'r'))
          # TODO: Memoize config
        filenames = bundles.map { |b| config[type.to_s]['bundles'][b] }.
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
        if  use_caching &&
            rails_asset_id(File.join(assets_dir, min_filename_with_ext)).present?
          # This condition takes advantage of the caching built into
          # `rails_asset_id`.
          sources << min_filename_with_ext  # Use minified version
        else
          sources << "#{filename}.#{type}"  # Use original version
        end
      end
    end

    sources.uniq!
    sources.map do |src|
      # TODO: If use_caching, bust cache with git-sha of last modified file
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
    #   =>  <script src="/javascripts/jquery-1.3.2.min.js" ...></script>
    #   include_js :jquery  # Staging/production environment
    #   =>  <script src="http://ajax.googleapis.com/.../jquery.min.js" ...></script>
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

    if args.include?(:jquery)
      args.delete :jquery
      source = (Rails.env.development? || Rails.env.test?) ?
        'jquery-1.3.2.min.js' :
        'http://ajax.googleapis.com/ajax/libs/jquery/1.3.2/jquery.min.js'
      html << include_assets(:js, source)
    end

    html << include_assets(:js, *args)
    html.join("\n").strip
  end

end

# Helpers for use in layouts for global includes, and in views for
# view-specific includes.
module AssetHatHelper
  unless defined?(RAILS_ROOT)
    RAILS_ROOT = File.join(File.dirname(__FILE__), '..', '..')
  end

  # Includes CSS or JS files. <code>include_css</code> and
  # <code>include_js</code> are recommended instead.
  def include_assets(type, *args) #:nodoc:
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

    options   = args.extract_options!.symbolize_keys
    filenames = [] # May or may not have proper extensions
    sources   = [] # The URLs that are ultimately included via HTML
    source_commit_ids = {} # Last commit ID for each source

    # If `use_caching` is `true`, bundles and minified code will be used:
    use_caching = AssetHat.cache?
    use_caching = options[:cache] unless options[:cache].nil?
    options.delete :cache # Completely avoid Rails' built-in caching

    # Gather list of filenames, which may not have proper extensions yet
    filenames = args.dup
    if options[:bundle].present? || options[:bundles].present?
      bundles = [options.delete(:bundle), options.delete(:bundles)].
                  flatten.reject(&:blank?)
      if use_caching
        filenames += bundles.map do |bundle|
          File.join(AssetHat.bundles_dir(options.slice(:ssl)),
                    "#{bundle}.min.#{type}")
        end
      else
        config = AssetHat.config
        filenames += bundles.map { |b| AssetHat.bundle_filenames(b, type) }.
                      flatten.reject(&:blank?)
      end
    end

    # Build `sources`, adding extensions if needed, using minified file if it
    # already exists
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
        if src =~ %r{^http(s?)://} || src =~ %r{^//}
          # Absolute URL; do nothing
        elsif src =~ /^#{AssetHat.bundles_dir}\//
          # Get commit ID of bundle file with most recently committed update
          bundle = src.
            match(/^#{AssetHat.bundles_dir}\/(ssl\/)?(.*)\.min\.#{type}$/).
            to_a.last
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

    # Prepare return value
    options.delete :ssl
    if options[:only_url]
      # Return only asset URLs, not HTML inclusions
      source_urls = sources.map { |source| asset_path_by_type(source, type) }
      source_urls.size == 1 ? source_urls.first : source_urls
    else
      html = sources.map do |src|
        case type
        when :css then stylesheet_link_tag(src, options)
        when :js  then javascript_include_tag(src, options)
        else nil
        end
      end.join("\n")
      make_html_safe html
    end

  end # def include_assets

  # <code>include_css</code> is a smart wrapper for Rails'
  # <code>stylesheet_link_tag</code>. The two can be used together while
  # migrating to AssetHat.
  #
  # Include a single, minified stylesheet:
  #   include_css 'diagnostics'
  #   =>  <link href="/stylesheets/diagnostics.min.css" media="screen,projection" rel="stylesheet" type="text/css" />
  #
  # Include a single, unminified stylesheet:
  #   include_css 'diagnostics.css'
  #   =>  <link href="/stylesheets/diagnostics.css" media="screen,projection" rel="stylesheet" type="text/css" />
  #
  # Include a bundle of stylesheets (i.e., a concatenated set of
  # stylesheets; configure in config/assets.yml):
  #   include_css :bundle => 'application'
  #   =>  <link href="/stylesheets/bundles/application.min.css" ... />
  #
  # Include multiple stylesheets separately (not as cool):
  #   include_css 'reset', 'application'
  #   =>  <link href="/stylesheets/reset.min.css" ... />
  #       <link href="/stylesheets/application.min.css" ... />
  #
  # Include a stylesheet with extra media types:
  #   include_css 'mobile', :media => 'handheld,screen,projection'
  #   =>  <link href="/stylesheets/mobile.min.css"
  #             media="handheld,screen,projection" ... />
  #
  # Get the URL for a single, minified stylesheet:
  #   include_css 'diagnostics', :only_url => true
  #   => '/stylesheets/diagnostics.min.css'
  #
  # Get the URL for a single, unminified stylesheet:
  #   include_css 'diagnostics.css', :only_url => true
  #   => '/stylesheets/diagnostics.css'
  #
  # Get the URL for a bundle of stylesheets when environment *enables* caching
  # (e.g., staging, production):
  #   include_css :bundle => 'application', :only_url => true
  #   => '/stylesheets/bundles/application.min.css'
  #
  # Get URLs for a bundle of stylesheets when environment *disables* caching
  # (e.g., development, test):
  #   include_css :bundle => 'application', :only_url => true
  #   => ['/stylesheets/reset.css', '/stylesheets/common.css', ...]
  #
  # Get URLs for multiple stylesheets manually:
  #   include_css 'reset', 'application', :only_url => true
  #   => ['/stylesheets/reset.css', '/stylesheets/application.css']
  def include_css(*args)
    return if args.blank?

    initialize_html_cache :css

    options = setup_options(args,
      :media => 'screen,projection',
      :ssl => controller.request.ssl?
    )
    cache_key = setup_cache_key(args, options)

    if !asset_cached?(:css, cache_key)
      # Generate HTML and write to cache
      options[:ssl] &&= AssetHat.ssl_asset_host_differs?
      html = AssetHat.html_cache[:css][cache_key] =
        include_assets(:css, *(args + [options]))
    end

    html ||= AssetHat.html_cache[:css][cache_key]
    make_html_safe html
  end

  # <code>include_js</code> is a smart wrapper for Rails'
  # <code>javascript_include_tag</code>. The two can be used together while
  # migrating to AssetHat.
  #
  # Include a single, minified JS file:
  #   include_js 'application'
  #   =>  <script src="/javascripts/application.min.js" type="text/javascript"></script>
  #
  # Include a single, unminified JS file:
  #   include_js 'application.js'
  #   =>  <script src="/javascripts/application.js" type="text/javascript"></script>
  #
  # Include jQuery:
  #   # Development/test environment:
  #   include_js :jquery
  #   =>  <script src="/javascripts/jquery-VERSION.min.js" ...></script>
  #
  #   # Staging/production environment:
  #   include_js :jquery
  #   =>  <script src="http://ajax.googleapis.com/.../jquery.min.js" ...></script>
  #     # Set jQuery versions either in `config/assets.yml`, or by using
  #     # `include_js :jquery, :version => '1.6.1'`.
  #
  # Include a bundle of JS files (i.e., a concatenated set of files;
  # configure in <code>config/assets.yml</code>):
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
  #
  # Get the URL for a single, minified JS file:
  #   include_js 'application', :only_url => true
  #   =>  '/javascripts/application.min.js'
  #
  # Get the URL for a single, unminified JS file:
  #   include_js 'application.js', :only_url => true
  #   =>  '/javascripts/application.js', :only_url => true
  #
  # Get the URL for jQuery:
  #   # Development/test environment:
  #   include_js :jquery, :only_url => true
  #   =>  '/javascripts/jquery-VERSION.min.js'
  #
  #   # Staging/production environment:
  #   include_js :jquery, :only_url => true
  #   =>  'http://ajax.googleapis.com/.../jquery.min.js'
  #
  # Get the URL for a bundle of JS files when environment *enables* caching
  # (e.g., staging, production):
  #   include_js :bundle => 'application', :only_url => true
  #   => '/javascripts/bundles/application.min.js'
  #
  # Get URLs for a bundle of JS files when environment *disables* caching
  # (e.g., development, test):
  #   include_js :bundle => 'application', :only_url => true
  #   => ['/javascripts/jquery.plugin-foo.js',
  #       '/javascripts/jquery.plugin-bar.min.js',
  #       '/javascripts/json2.js',
  #       ...]
  #
  # Get URLs for multiple JS files manually:
  #   include_js 'json2', 'application', :only_url => true
  #   => ['/javascripts/json2.js', '/javascripts/application.js']
  #
  # Load JS files with {LABjs}[http://labjs.com] (hosted either from cdnjs or
  # your own web server, if found in <code>public/javascripts/</code>):
  #
  #   # config/assets.yml:
  #   js:
  #     vendors:
  #       lab_js:
  #         version: 1.x.x
  #
  #   # Usage:
  #   include_js :jquery, :bundle => 'application', :loader => :lab_js
  #   =>  <script src="http://ajax.cdnjs.com/.../1.x.x/LAB.min.js" ...></script>
  #       <script type="text/javascript">
  #       window.$LABinst=$LAB.
  #         script('http://ajax.googleapis.com/.../jquery.min.js').wait().
  #         script('/javascripts/bundles/application.min.js').wait();
  #       </script>
  #
  #   # For advanced fine-tuning, build the LABjs calls manually (based on
  #   # example from http://labjs.com/documentation.php ):
  #   <script>
  #      window.$LABinst = $LAB.
  #        script('<%= include_js 'framework', :only_url => true %>').wait().
  #        script('<%= include_js 'plugin.framework.js',
  #                               :only_url => true %>').
  #        script('<%= include_js 'myplugin.framework.js',
  #                               :only_url => true %>').wait().
  #        script('<%= include_js 'init.js', :only_url => true %>').wait();
  #   </script>
  #
  #   # If you want to execute an inline <script> block that relies on any
  #   # of these dependencies, use the JS variable `window.$LABinst`.
  #   # Example (using jQuery to handle when DOM is ready):
  #   <script>
  #   window.$LABinst(function(){
  #     console.log('JS dependencies are ready');
  #     $(function(){
  #       console.log('DOM is ready');
  #     });
  #   });
  #   </script>
  def include_js(*args)
    return if args.blank?

    initialize_html_cache :js

    options = setup_options(args, :ssl => controller.request.ssl?)
    cache_key = setup_cache_key(args, options)

    if !asset_cached?(:js, cache_key)
      # Generate HTML and write to cache

      htmls = []
      include_assets_options = options.except(:ssl, :version)

      loader = options.delete(:loader)
      include_assets_options.merge!(:only_url => true) if loader

      # Get vendor HTML/URLs
      included_vendors = (args & AssetHat::JS::VENDORS)

      # Add HTML inclusions for vendors
      included_vendors.each do |vendor|
        args.delete vendor
        src = AssetHat::JS::Vendors.source_for(
                vendor, options.slice(:ssl, :version))
        htmls << include_assets(:js, src,
                  include_assets_options.merge(:cache => true).
                                         except(:bundle, :bundles))
      end

      # Get non-vendor HTML/URLs
      htmls << include_assets(:js, *(args + [include_assets_options]))
      htmls.reject!(&:blank?)

      if loader
        # `htmls` actually contains URLs; convert to an HTML/JS block
        urls  = htmls.dup.flatten
        htmls = []

        case loader
        when :lab_js
          htmls << include_js(:lab_js)
          htmls << '<script type="text/javascript">'
          htmls << AssetHat::JS::Vendors.loader_js(:lab_js, :urls => urls)
          htmls << '</script>'
        end
      end

      # Convert to a URL (string), array of URLs, or one long HTML string
      html =  if options[:only_url]
                # Return one URL (string) or multiple (array of strings).
                # Not actually HTML.
                htmls.flatten!
                htmls.size == 1 ? htmls.first : htmls
              else
                # Return one long string of HTML
                htmls.join("\n").strip
              end
      AssetHat.html_cache[:js][cache_key] = html
    end

    html ||= AssetHat.html_cache[:js][cache_key]
    make_html_safe html
  end

  # Returns the public URL path to the given source file.
  #
  # <code>type</code> argument: <code>:css</code> or <code>:js</code>
  def asset_path_by_type(source, type)
    case type.to_sym
    when :css ; stylesheet_path(source)
    when :js  ; javascript_path(source)
    else
      raise %{
        Unknown type "#{type}"; should be one of:
        #{AssetHat::TYPES.join(', ')}.
      }.squish!
    end
  end

  private

  def initialize_html_cache(type)
    AssetHat.html_cache ||= {}
    AssetHat.html_cache[type] ||= {}
  end

  def setup_options(args, defaults)
    options = args.extract_options!
    options.symbolize_keys!.reverse_merge!(defaults)
  end

  def setup_cache_key(args, options)
    (args + [options]).inspect
  end

  def make_html_safe(html)
    html.respond_to?(:html_safe) ? html.html_safe : html
  end

  def asset_cached?(type, cache_key)
    AssetHat.cache? && !AssetHat.html_cache[type.to_sym][cache_key].blank?
  end
end

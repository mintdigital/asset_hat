%w[css js vcs].each do |x|
  require File.join(File.dirname(__FILE__), 'asset_hat', x)
end

# Your assets are covered.
#
# With Rails' default asset caching, CSS and JS are concatenated (not even
# minified) at runtime when that bundle is first requested. Not good enough.
# AssetHat can automatically:
#
# * Easily *minify* and *bundle* CSS and JS on deploy to reduce file sizes and
#   HTTP requests.
# * Load popular <strong>third-party JS</strong> (like jQuery and Prototype)
#   from {<strong>Google's CDN</strong>}[http://code.google.com/apis/ajaxlibs/]
#   when in production, or from localhost in development.
# * Force image URLs in your CSS to use <strong>CDN subdomains</strong>, not
#   just the current host.
# * Add an image's last Git[http://git-scm.com/] commit ID to its CSS URLs to
#   <strong>bust browser caches</strong> (e.g.,
#   <code>/images/foo.png?ab12cd3</code>).
#
# After setup, you can use these in your layouts and views:
#
#     <%= include_css :bundle => 'application' %>
#       # => <link href="/stylesheets/bundles/application.min.css"
#       #          media="screen,projection" rel="stylesheet" type="text/css" />
#
#     <%= include_js :bundles => ['plugins', 'common'] %>
#       # => <script src="/javascripts/bundles/plugins.min.js"
#       #            type="text/javascript"></script>
#       #    <script src="/javascripts/bundles/common.min.js"
#       #            type="text/javascript"></script>
#
# And this in your deploy script:
#
#     rake asset_hat:minify
#
# See README.rdoc for more.
module AssetHat
  RAILS_ROOT = File.join(File.dirname(__FILE__), '..') unless defined?(RAILS_ROOT) #:nodoc:

  # Types of supported assets; currently <code>[:css, :js]</code>.
  TYPES = [:css, :js]

  # Base directory in which all assets are kept, e.g., 'public/'.
  ASSETS_DIR = defined?(Rails.public_path) ? Rails.public_path : 'public'

  # Directory in which all stylesheets are kept, e.g., 'public/stylesheets/'.
  STYLESHEETS_DIR = File.join(ASSETS_DIR, 'stylesheets')

  # Directory in which all JavaScripts are kept, e.g., 'public/javascripts/'.
  JAVASCRIPTS_DIR = File.join(ASSETS_DIR, 'javascripts')

  # Relative path for the config file.
  RELATIVE_CONFIG_FILEPATH = File.join('config', 'assets.yml')

  # Absolute path for the config file.
  CONFIG_FILEPATH = File.join(RAILS_ROOT, RELATIVE_CONFIG_FILEPATH)

  class << self
    attr_accessor :config, :asset_exists, :html_cache #:nodoc:
  end

  # Nested-hash version of <code>config/assets.yml</code>.
  def self.config
    if !cache? || @config.blank?
      @config = YAML.load(ERB.new(File.read(CONFIG_FILEPATH)).result)
    end
    @config
  end

  # Returns the relative path to the directory where the original CSS or JS
  # files are stored.
  #
  # <code>type</code> argument: <code>:css</code> or <code>:js</code>
  def self.assets_dir(type)
    type = type.to_sym

    unless TYPES.include?(type)
      raise "Unknown type \"#{type}\"; should be one of: #{TYPES.join(', ')}."
      return
    end

    case type
    when :css ; STYLESHEETS_DIR
    when :js  ; JAVASCRIPTS_DIR
    else nil
    end
  end

  # Returns the relative path to the directory where CSS or JS bundles are
  # stored.
  #
  # Usage:
  #
  #     AssetHat.bundles_dir
  #       # => 'bundles'
  #     AssetHat.bundles_dir(:ssl => true)
  #       # => 'bundles/ssl'
  #     AssetHat.bundles_dir(:css)
  #       # => 'public/stylesheets/bundles'
  #     AssetHat.bundles_dir(:js, :ssl => true)
  #       # => 'public/javascripts/bundles/ssl
  #
  # Options:
  #
  # [ssl] Set this to <code>true</code> if the stylesheet references images
  #       via SSL. Defaults to <code>false</code>.
  def self.bundles_dir(*args)
    options = args.extract_options!
    options.symbolize_keys!.reverse_merge!(:ssl => false)
    type = args.first

    dir = type.present? ? File.join(assets_dir(type), 'bundles') : 'bundles'
    dir = File.join(dir, 'ssl') if options[:ssl]
    dir
  end

  # Returns true if the specified asset exists in the file system:
  #
  #     AssetHat.asset_exists?('application.css', :css)
  #       # => true if public/stylesheets/application.css exists
  #     AssetHat.asset_exists?('some-plugin.js', :js)
  #       # => true if public/javascripts/some-plugin.js exists
  #
  # See also <code>AssetHat.assets_dir</code>.
  def self.asset_exists?(filename, type)
    # Process arguments
    type = type.to_sym
    unless TYPES.include?(type)
      raise "Unknown type \"#{type}\"; should be one of: #{TYPES.join(', ')}."
      return
    end

    # Default to `{:css => {}, :js => {}}`
    @asset_exists ||= TYPES.inject({}) { |hsh, t| hsh.merge(t => {}) }

    if @asset_exists[type][filename].nil?
      @asset_exists[type][filename] =
        File.exist?(File.join(self.assets_dir(type), filename))
    end
    @asset_exists[type][filename]
  end

  # Returns <code>true</code> if bundles should be included as single minified
  # files (e.g., in production), or <code>false</code> if bundles should be
  # included as separate, unminified files (e.g., in development). To modify
  # this value, set <code>config.action_controller.perform_caching = true</code>
  # in your environment.
  def self.cache? ; ActionController::Base.perform_caching ; end

  # Returns the expected path for the minified version of an asset:
  #
  #     AssetHat.min_filepath('public/stylesheets/bundles/application.css', 'css')
  #       # => 'public/stylesheets/bundles/application.min.css'
  #
  # See also <code>AssetHat::CSS.min_filepath</code> and
  # <code>AssetHat::JS.min_filepath</code>.
  def self.min_filepath(filepath, extension)
    filepath.sub(/([^\.]*).#{extension}$/, "\\1.min.#{extension}")
  end

  # Returns the extension-less names of files in the given bundle:
  #
  #     AssetHat.bundle_filenames('application', :css)
  #       # => ['reset', 'application', 'clearfix']
  #     AssetHat.bundle_filenames('non-existent-file', :css)
  #       # => nil
  def self.bundle_filenames(bundle, type)
    # Process arguments
    unless TYPES.include?(type.to_sym)
      raise "Unknown type \"#{type}\"; should be one of: #{TYPES.join(', ')}."
      return
    end

    self.config[type.to_s]['bundles'][bundle.to_s] rescue nil
  end

  # Returns the full paths of files in the given bundle:
  #
  #     AssetHat.bundle_filenames('application', :css)
  #       # => ['/path/to/app/public/stylesheets/reset.css',
  #             '/path/to/app/public/stylesheets/application.css',
  #             '/path/to/app/public/stylesheets/clearfix.css']
  #     AssetHat.bundle_filenames('non-existent-file', :css)
  #       # => nil
  def self.bundle_filepaths(bundle, type)
    # Process arguments
    unless TYPES.include?(type.to_sym)
      raise "Unknown type \"#{type}\"; should be one of: #{TYPES.join(', ')}."
      return
    end

    dir = self.assets_dir(type)
    filenames = self.bundle_filenames(bundle, type)
    filepaths = filenames.present? ?
      filenames.map { |fn| File.join(dir, "#{fn}.#{type}") } : nil
  end

  # Reads <code>ActionController::Base.asset_host</code>, which can be a
  # String or Proc, and returns a String. Should behave just like Rails
  # 2.3.x's private `compute_asset_host` method, but with a simulated request.
  #
  # Example environment config for CDN support via SSL:
  #
  #     # In config/environments/production.rb:
  #     config.action_controller.asset_host = Proc.new do |source, request|
  #       "#{request.protocol}cdn#{source.hash % 4}.example.com"
  #         # => 'http://cdn0.example.com', 'https://cdn1.example.com', etc.
  #     end
  #
  # If your CDN doesn't have SSL support, you can instead revert SSL pages to
  # serving assets from your web server:
  #
  #     config.action_controller.asset_host = Proc.new do |source, request|
  #       request.ssl? ? nil : "http://cdn#{source.hash % 4}.example.com"
  #     end
  #
  # Options:
  #
  # [ssl] Set to <code>true</code> to simulate a request via SSL. Defaults to
  #       <code>false</code>.
  def self.compute_asset_host(asset_host, source, options={})
    host = asset_host
    if host.is_a?(Proc) || host.respond_to?(:call)
      case host.is_a?(Proc) ?
           host.arity : host.method(:call).arity
      when 2
        request = ActionController::Request.new(
          'HTTPS' => options[:ssl] ? 'on' : 'off')
        host = host.call(source, request)
      else
        host = host.call(source)
      end
    else
      host %= (source.hash % 4) if host =~ /%d/
    end
    host
  end

  # Returns <code>true</code> if the asset host differs between SSL and
  # non-SSL pages, or <code>false</code> if the asset host doesn't change.
  def self.ssl_asset_host_differs?
    asset_host = ActionController::Base.asset_host
    AssetHat.compute_asset_host(asset_host, 'x.png') !=
      AssetHat.compute_asset_host(asset_host, 'x.png', :ssl => true)
  end

  def self.clear_html_cache
    html_cache = {}
  end

end

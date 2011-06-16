%w[css js vcs].each do |filename|
  require File.join(File.dirname(__FILE__), 'asset_hat', filename)
end

# Your assets are covered. See README.rdoc for more.
module AssetHat
  if defined?(Rails) && Rails::VERSION::MAJOR >= 3
    RAILS_ROOT = Rails.root || '.' #:nodoc:
    require 'asset_hat/railtie'
  else
    RAILS_ROOT = File.join(File.dirname(__FILE__), '..') unless
      defined?(RAILS_ROOT) #:nodoc:
  end

  # Types of supported assets; currently <code>[:css, :js]</code>.
  TYPES = [:css, :js]

  # Base directory in which all assets are kept, e.g., 'public/'.
  ASSETS_DIR = defined?(Rails.public_path) && Rails.public_path.present? ?
    Rails.public_path : 'public'

  # Root URL path for all stylesheets. For public-facing use.
  STYLESHEETS_PATH = '/stylesheets'

  # Root URL path for all JavaScripts. For public-facing use.
  JAVASCRIPTS_PATH = '/javascripts'

  # Directory in which all stylesheets are kept, e.g., 'public/stylesheets'.
  # For internal filesystem use.
  STYLESHEETS_DIR = File.join(ASSETS_DIR, 'stylesheets')

  # Directory in which all JavaScripts are kept, e.g., 'public/javascripts'.
  # For internal filesystem use.
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
    unless File.exists?(CONFIG_FILEPATH)
      raise '`config/assets.yml` is missing! ' +
            'Run `rake asset_hat:config` to generate it.' and return
    end

    if !cache? || @config.blank?
      @config = YAML.load(ERB.new(File.read(CONFIG_FILEPATH)).result)
    end
    @config
  end

  # Returns the relative path to the directory where the original CSS or JS
  # files are stored. For internal filesystem use.
  #
  # <code>type</code> argument: <code>:css</code> or <code>:js</code>
  def self.assets_dir(type)
    case type.to_sym
    when :css ; STYLESHEETS_DIR
    when :js  ; JAVASCRIPTS_DIR
    else
      raise %{Unknown type "#{type}"; should be one of: #{TYPES.join(', ')}.}
      nil
    end
  end

  # Returns the root URL path where the original CSS or JS files are stored.
  # For external URL-building use.
  #
  # <code>type</code> argument: <code>:css</code> or <code>:js</code>
  def self.assets_path(type)
    case type.to_sym
    when :css ; STYLESHEETS_PATH
    when :js  ; JAVASCRIPTS_PATH
    else
      raise %{Unknown type "#{type}"; should be one of: #{TYPES.join(', ')}.}
      nil
    end
  end

  # Returns the relative path to the directory where CSS or JS bundles are
  # stored. For internal filesystem use.
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

  # Returns the root URL path where CSS or JS bundles are stored. For external
  # URL-building use.
  #
  # Usage:
  #
  #     AssetHat.bundles_path(:css)
  #       # => 'public/stylesheets/bundles'
  #     AssetHat.bundles_path(:js, :ssl => true)
  #       # => 'public/javascripts/bundles/ssl
  #
  # Options:
  #
  # [ssl] Set this to <code>true</code> if the stylesheet references images
  #       via SSL. Defaults to <code>false</code>.
  def self.bundles_path(type, options={})
    type = type.to_sym
    unless TYPES.include?(type)
      raise %{Unknown type "#{type}"; should be one of: #{TYPES.join(', ')}.}
      return
    end

    path =  case type
            when :css ; STYLESHEETS_PATH
            when :js  ; JAVASCRIPTS_PATH
            else nil
            end
    path += '/bundles'
    path += '/ssl' if options[:ssl]
    path
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
      raise %{Unknown type "#{type}"; should be one of: #{TYPES.join(', ')}.}
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
  # this value, set
  # <code>config.action_controller.perform_caching</code> (boolean)
  # in your environment.
  def self.cache? ; ActionController::Base.perform_caching ; end

  # Returns the value of
  # <code>Rails.application.config.consider_all_requests_local</code> or its
  # equivalent in older versions of Rails. To modify this value, set
  # <code>config.consider_all_requests_local</code> (boolean) in your
  # environment.
  def self.consider_all_requests_local?
    if defined?(Rails) && Rails.respond_to?(:application)
      Rails.application.config.consider_all_requests_local
    else # Rails 2.x
      ActionController::Base.consider_all_requests_local
    end
  end

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
  #       # => ['reset', 'application']
  #     AssetHat.bundle_filenames('non-existent-file', :css)
  #       # => nil
  def self.bundle_filenames(bundle, type)
    # Process arguments
    unless TYPES.include?(type.to_sym)
      raise %{Unknown type "#{type}"; should be one of: #{TYPES.join(', ')}.}
      return
    end

    self.config[type.to_s]['bundles'][bundle.to_s] rescue nil
  end

  # Returns the full paths of files in the given bundle:
  #
  #     AssetHat.bundle_filenames('application', :css)
  #       # => ['/path/to/app/public/stylesheets/reset.css',
  #             '/path/to/app/public/stylesheets/application.css']
  #     AssetHat.bundle_filenames('non-existent-file', :css)
  #       # => nil
  def self.bundle_filepaths(bundle, type)
    # Process arguments
    unless TYPES.include?(type.to_sym)
      raise %{Unknown type "#{type}"; should be one of: #{TYPES.join(', ')}.}
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
        if defined?(ActionDispatch)
          request_class = ActionDispatch::Request
        else # Rails 2.x
          request_class = ActionController::Request
        end
        request = request_class.new(
          'HTTPS' => options[:ssl] ? 'on' : 'off')
        host = host.call(source, request)
      else
        host = host.call(source)
      end
    else
      host %= (source.hash % 4) if host =~ /%d/
    end
    host == "https://:" ? "" : host
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

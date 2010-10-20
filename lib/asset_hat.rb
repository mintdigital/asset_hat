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
#   <code>/images/foo.png?ab12cd34e</code>).
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
  STYLESHEETS_DIR = "#{ASSETS_DIR}/stylesheets"

  # Directory in which all JavaScripts are kept, e.g., 'public/javascripts/'.
  JAVASCRIPTS_DIR = "#{ASSETS_DIR}/javascripts"

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

  # Argument: <code>:css</code> or <code>:js</code>
  #
  # Returns the path to the directory where CSS or JS files are stored.
  def self.assets_dir(type)
    case type.to_sym
    when :css ; STYLESHEETS_DIR
    when :js  ; JAVASCRIPTS_DIR
    else nil
    end
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

    self.config[type.to_s]['bundles'][bundle] rescue nil
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

  def self.clear_html_cache
    html_cache = {}
  end

end

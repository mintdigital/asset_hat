%w[css js vcs].each do |x|
  require File.join(File.dirname(__FILE__), 'asset_hat', x)
end

module AssetHat
  RAILS_ROOT      = File.join(File.dirname(__FILE__), '..') unless defined?(RAILS_ROOT)
  TYPES           = [:css, :js]
  ASSETS_DIR      = defined?(Rails.public_path) ? Rails.public_path : 'public'
  JAVASCRIPTS_DIR = "#{ASSETS_DIR}/javascripts"
  STYLESHEETS_DIR = "#{ASSETS_DIR}/stylesheets"
  RELATIVE_CONFIG_FILEPATH = File.join('config', 'assets.yml')
  CONFIG_FILEPATH = File.join(RAILS_ROOT, RELATIVE_CONFIG_FILEPATH)

  class << self
    attr_accessor :config, :asset_exists, :html_cache #:nodoc:
  end

  # Nested-hash version of <tt>config/assets.yml</tt>.
  def self.config
    if !cache? || @config.blank?
      @config = YAML.load(File.open(CONFIG_FILEPATH, 'r'))
    end
    @config
  end

  # Argument: <tt>:css</tt> or <tt>:js</tt>
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
  #     AssetHat.asset_exists?('application', :css)
  #       # =>  <tt>true</tt> if <tt>/public/stylesheets/application.css</tt>
  #             exists
  #     AssetHat.asset_exists?('some-plugin', :js)
  #       # =>  <tt>true</tt> if <tt>/public/javascripts/some-plugin.js</tt>
  #             exists
  #
  # See also <tt>AssetHat::STYLESHEETS_DIR</tt> and
  # <tt>AssetHat::JAVASCRIPTS_DIR</tt>.
  def self.asset_exists?(filename, type)
    # Process arguments
    type = type.to_sym
    unless TYPES.include?(type)
      raise "Unknown type \"#{type}\"; should be one of: #{TYPES.join(', ')}."
      return
    end

    @asset_exists ||= TYPES.inject({}) do |hsh, known_type|
      hsh.merge!(known_type => {})
    end
    if @asset_exists[type][filename].nil?
      @asset_exists[type][filename] =
        File.exist?(File.join(self.assets_dir(type), filename))
    end
    @asset_exists[type][filename]
  end

  # Returns +true+ if bundles should be included as single minified files
  # (e.g., in production), or +false+ if bundles should be included as
  # separate, unminified files (e.g., in development). To modify this value,
  # set <tt>config.action_controller.perform_caching = true</tt> in your
  # environment.
  def self.cache? ; ActionController::Base.perform_caching ; end

  # Returns the expected path for the minified version of an asset:
  #
  #     AssetHat.min_filepath('public/stylesheets/bundles/application.css')
  #       # => 'public/stylesheets/bundles/application.min.css'
  #
  # See also <tt>AssetHat::CSS.min_filepath</tt> and
  # <tt>AssetHat::JS.min_filepath</tt>.
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

end

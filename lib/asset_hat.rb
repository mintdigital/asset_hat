%w[css js vcs].each do |x|
  require File.join(File.dirname(__FILE__), 'asset_hat', x)
end

module AssetHat
  RAILS_ROOT      = File.join(File.dirname(__FILE__), '..') unless defined?(RAILS_ROOT)
  TYPES           = [:css, :js]
  ASSETS_DIR      = defined?(Rails.public_path) ? Rails.public_path : 'public'
  JAVASCRIPTS_DIR = "#{ASSETS_DIR}/javascripts"
  STYLESHEETS_DIR = "#{ASSETS_DIR}/stylesheets"
  CONFIG_FILEPATH = File.join(RAILS_ROOT, 'config', 'assets.yml')

  class << self
    attr_accessor :include_html_cache
  end

  def self.config
    @@config ||= YAML.load(File.open(CONFIG_FILEPATH, 'r'))
  end

  def self.assets_dir(type)
    case type.to_sym
    when :css ; STYLESHEETS_DIR
    when :js  ; JAVASCRIPTS_DIR
    end
  end

  def self.asset_exists?(filename, type)
    # Process arguments
    type = type.to_sym
    unless TYPES.include?(type)
      raise "Unknown type \"#{type}\"; should be one of: #{TYPES.join(', ')}."
      return
    end

    @@asset_exists ||= TYPES.inject({}) do |hsh, known_type|
      hsh.merge!(known_type => {})
    end
    if @@asset_exists[type][filename].nil?
      @@asset_exists[type][filename] =
        File.exist?(File.join(self.assets_dir(type), filename))
    end
    @@asset_exists[type][filename]
  end

  def self.cache? ; ActionController::Base.perform_caching ; end

  def self.min_filepath(filepath, extension)
    filepath.sub(/([^\.]*).#{extension}$/, "\\1.min.#{extension}")
  end

  def self.bundle_filenames(bundle, type)
    # Usage:
    #
    #     AssetHat.bundle_filenames('application', :css)
    #       # => ['reset', 'application', 'clearfix']
    #     AssetHat.bundle_filenames('non-existent-file', :css)
    #       # => nil

    # Process arguments
    unless TYPES.include?(type.to_sym)
      raise "Unknown type \"#{type}\"; should be one of: #{TYPES.join(', ')}."
      return
    end

    self.config[type.to_s]['bundles'][bundle] rescue nil
  end

  def self.bundle_filepaths(bundle, type)
    # Usage:
    #
    #     AssetHat.bundle_filenames('application', :css)
    #       # => ['reset', 'application', 'clearfix']
    #     AssetHat.bundle_filenames('non-existent-file', :css)
    #       # => nil

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

__DIR__ = File.dirname(__FILE__)
require File.join(__DIR__, %w[asset_hat css])
require File.join(__DIR__, %w[asset_hat js])

module AssetHat
  RAILS_ROOT = File.join(File.dirname(__FILE__), '..') unless defined?(RAILS_ROOT)
  CONFIG_FILEPATH = File.join(RAILS_ROOT, 'config', 'assets.yml')
  TYPES = [:css, :js]

  def self.config
    @@config ||= YAML::load(File.open(CONFIG_FILEPATH, 'r'))
  end

  def self.min_filepath(filepath, extension)
    filepath.sub(/([^\.]*).#{extension}$/, "\\1.min.#{extension}")
  end

  def self.bundle_filenames(bundle, type)
    # Usage:
    #
    #     AssetHat::bundle_filenames('application', :css)
    #       # => ['reset', 'application', 'clearfix']

    # Process arguments
    type = type.to_s
    unless TYPES.include?(type.to_sym)
      raise "Unknown type \"#{type}\"; should be one of: #{TYPES.join(', ')}."
      return
    end

    config[type]['bundles'][bundle]
  end

end

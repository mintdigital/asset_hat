__DIR__ = File.dirname(__FILE__)
require File.join(__DIR__, %w[asset_hat css])
require File.join(__DIR__, %w[asset_hat js])

module AssetHat
  RAILS_ROOT      = File.join(File.dirname(__FILE__), '..') unless defined?(RAILS_ROOT)
  TYPES           = [:css, :js]
  ASSETS_DIR      = defined?(Rails.public_path) ? Rails.public_path : 'public'
  JAVASCRIPTS_DIR = "#{ASSETS_DIR}/javascripts"
  STYLESHEETS_DIR = "#{ASSETS_DIR}/stylesheets"
  CONFIG_FILEPATH = File.join(RAILS_ROOT, 'config', 'assets.yml')

  def self.config
    @@config ||= YAML::load(File.open(CONFIG_FILEPATH, 'r'))
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
    #     AssetHat::bundle_filenames('application', :css)
    #       # => ['reset', 'application', 'clearfix']
    #     AssetHat::bundle_filenames('non-existent-file', :css)
    #       # => nil

    # Process arguments
    unless TYPES.include?(type.to_sym)
      raise "Unknown type \"#{type}\"; should be one of: #{TYPES.join(', ')}."
      return
    end

    self.config[type.to_s]['bundles'][bundle]
  end

  def self.bundle_filepaths(bundle, type)
    # Usage:
    #
    #     AssetHat::bundle_filenames('application', :css)
    #       # => ['reset', 'application', 'clearfix']
    #     AssetHat::bundle_filenames('non-existent-file', :css)
    #       # => nil

    # Process arguments
    unless TYPES.include?(type.to_sym)
      raise "Unknown type \"#{type}\"; should be one of: #{TYPES.join(', ')}."
      return
    end

    dir = self.assets_dir(type)
    filenames = self.bundle_filenames(bundle, type)
    filepaths = filenames.map { |fn| File.join(dir, "#{fn}.#{type}") }
  end

  def self.last_commit_id(*args)
    # Usage:
    #
    #     AssetHat::last_commit_id('public/stylesheets/application.css')
    #     AssetHat::last_commit_id('public/stylesheets/ie.css',
    #                              'public/stylesheets/ie7.css',
    #                              'public/stylesheets/ie6.css')
    #
    # Returns a string of the commit ID for the file with the most recent
    # commit. If the file(s) cannot be found, `nil` is returned.

    # Process arguments
    options = args.extract_options!
    options = options.symbolize_keys.reverse_merge(:vcs => :git)
    filepaths = args.join(' ')

    # Validate options
    if options[:vcs] != :git
      raise 'Git is currently the only supported VCS.' and return
    end

    @@last_commit_ids ||= {}
    if @@last_commit_ids[filepaths].blank?
      h = `git log -1 --pretty=format:%H #{filepaths} 2>/dev/null`
      @@last_commit_ids[filepaths] = h if h.present?
    end
    @@last_commit_ids[filepaths]
  end

  def self.last_bundle_commit_id(bundle, type)
    # Usage:
    #
    #     AssetHat::last_bundle_commit_id('application', :css)
    #
    # Returns a string of the latest commit ID for the given bundle, based
    # on which of its files were most recently modified in the repository. If
    # no ID can be found, `nil` is returned.

    # Process arguments
    type = type.to_sym
    unless TYPES.include?(type)
      raise "Unknown type \"#{type}\"; should be one of: #{TYPES.join(', ')}."
      return
    end

    # Default to `{:css => {}, :js => {}}`
    @@last_bundle_commit_ids ||=
      TYPES.inject({}) { |hsh, t| hsh.merge(t => {}) }

    if @@last_bundle_commit_ids[type][bundle].blank?
      dir = self.assets_dir(type)
      filepaths = self.bundle_filepaths(bundle, type)
      if filepaths.present?
        @@last_bundle_commit_ids[type][bundle] = self.last_commit_id(*filepaths)
      end
    end

    @@last_bundle_commit_ids[type][bundle]
  end

  def self.last_commit_ids ; @@last_commit_ids ; end

end

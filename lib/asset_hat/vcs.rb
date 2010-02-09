module AssetHat
  class << self
    attr_accessor :last_commit_ids, :last_bundle_commit_ids
  end

  def self.last_commit_id(*args)
    # Usage:
    #
    #     AssetHat.last_commit_id('public/stylesheets/application.css')
    #     AssetHat.last_commit_id('public/stylesheets/ie.css',
    #                             'public/stylesheets/ie7.css',
    #                             'public/stylesheets/ie6.css')
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

    @last_commit_ids ||= {}
    if @last_commit_ids[filepaths].blank?
      h = `git log -1 --pretty=format:%h #{filepaths} 2>/dev/null`
        # `h` has either the abbreviated Git commit hash or an empty string
      @last_commit_ids[filepaths] = h if h.present?
    end
    @last_commit_ids[filepaths]
  end

  def self.last_bundle_commit_id(bundle, type)
    # Usage:
    #
    #     AssetHat.last_bundle_commit_id('application', :css)
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
    @last_bundle_commit_ids ||=
      TYPES.inject({}) { |hsh, t| hsh.merge(t => {}) }

    if @last_bundle_commit_ids[type][bundle].blank?
      dir = self.assets_dir(type)
      filepaths = self.bundle_filepaths(bundle, type)
      if filepaths.present?
        @last_bundle_commit_ids[type][bundle] = self.last_commit_id(*filepaths)
      end
    end

    @last_bundle_commit_ids[type][bundle]
  end

  def self.last_commit_ids ; @last_commit_ids ; end

end

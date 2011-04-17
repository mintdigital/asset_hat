module AssetHat
  module JS
    # For working with supported 3rd-party JavaScript
    # plugin/framework/library vendors.
    module Vendors
      # A list of supported 3rd-party JavaScript plugin/vendor names.
      # Homepages:
      #
      # * {jQuery}[http://jquery.com/]
      # * {jQuery UI}[http://jqueryui.com/]
      # * {Prototype}[http://www.prototypejs.org/]
      # * {script.aculo.us}[http://script.aculo.us/]
      # * {MooTools}[http://mootools.net/]
      # * {Dojo}[http://dojotoolkit.org/]
      # * {SWFObject}[http://code.google.com/p/swfobject/]
      # * {YUI}[http://developer.yahoo.com/yui/]
      # * {Ext Core}[http://extjs.com/products/extcore/]
      # * {WebFont Loader}[http://code.google.com/apis/webfonts/docs/webfont_loader.html]
      VENDORS = [
        :jquery, :jquery_ui,
        :prototype, :scriptaculous,
        :mootools,
        :dojo,
        :swfobject,
        :yui,
        :ext_core,
        :webfont
      ]

      # Accepts an item from `VENDORS`, and returns the URL at which that
      # vendor asset can be found. The URL is either local (relative) or
      # remote, depending on the environment configuration:
      #
      # - If `AssetHat.consider_all_requests_local?` is true:
      #   - The local file takes precedence.
      #   - If the local file is missing, the remote URL in assets.yml is
      #     used as a fallback.
      #   - If there is no remote URL in assets.yml, the Google CDN URL is
      #     used as a fallback. (This makes setup easier: If the app doesn't
      #     already have a local copy of the vendor file, then it's instead
      #     loaded remotely.)
      # - If `AssetHat.consider_all_requests_local?` is false:
      #   - The remote URL in assets.yml takes precedence.
      #   - The {Google CDN}[http://code.google.com/apis/ajaxlibs/] URL is
      #     used as a fallback, but only if a version number can be found
      #     (either in assets.yml or via the helper's `:version` option). If
      #     no version number is found, the remote URL cannot be built, so
      #     the local file (if any) is used as a fallback.
      #
      # Options:
      #
      # [ssl]     Boolean for whether to include vendor JS via HTTPS. Defaults
      #           to false.
      # [version] The vendor version, e.g., '1.4.0' for jQuery 1.4. By
      #           default, each vendor version is taken from
      #           <code>config/assets.yml</code>; use this option to override
      #           the configuration.
      def self.source_for(vendor, options={})
        vendor_config =
          AssetHat.config['js']['vendors'][vendor.to_s] rescue nil
        use_local = AssetHat.consider_all_requests_local?
        use_ssl   = !!options[:ssl]
        version   = options[:version] || vendor_config['version'] rescue nil

        # Prepare local path and default remote URL
        srcs = Vendors.vendor_uris(vendor,
          :use_ssl => use_ssl, :version => version)
        local_src, remote_src = srcs[:local], srcs[:remote]

        # Using the local URL requires that the vendor file exists locally. If
        # the vendor file doesn't exist, use the remote URL as fallback.
        use_local &&= AssetHat.asset_exists?(local_src, :js)

        # If no version given, can't determine the remote URL; use the local
        # URL as fallback.
        use_local ||= version.blank?

        if use_local
          src = local_src
        else
          # To ease setup, if no local copy of the vendor code is found,
          # use a remote URL as a fallback.

          # Give precedence to configured remote URLs
          src   = vendor_config.try(:[], 'remote_ssl_url') if use_ssl
          src ||= vendor_config.try(:[], 'remote_url')

          # Use default remote URL as fallback
          src ||= remote_src

          # Use local URL as final resort, even though the file doesn't
          # exist, in hopes that the app maintainer finds the 404 (or the
          # warning below) in the logs. This needs to be fixed in the app,
          # rather than relying on a CDN to provide the latest stable vendor
          # version.
          src ||= local_src
          Rails.logger.warn "\n\nAssetHat WARNING (#{Time.now}):\n" + %{
            Tried to reference the vendor JS `:#{vendor}`, but
            #{AssetHat.assets_dir(:js)}/#{local_src} couldn't be found, and
            no vendor version was given in
            #{AssetHat::RELATIVE_CONFIG_FILEPATH}.
          }.squish!
            # TODO: Create `AssetHat::Logger.warn`, etc. methods
        end

        src
      end



      private

      def self.vendor_uris(vendor, options={})
        # Returns a hash with keys `:local` and `:remote`.

        uris    = {}
        use_ssl = options[:use_ssl]
        version = options[:version]

        case vendor
        when :jquery
          uris[:local ] = "#{['jquery', version].compact.join('-')}.min.js"
          uris[:remote] = "http#{'s' if use_ssl}://ajax.googleapis.com/ajax/libs/jquery/#{version}/jquery.min.js"
        when :jquery_ui
          uris[:local ] = "#{['jquery-ui', version].compact.join('-')}.min.js"
          uris[:remote] = "http#{'s' if use_ssl}://ajax.googleapis.com/ajax/libs/jqueryui/#{version}/jquery-ui.min.js"
        when :prototype
          # Prototype currently doesn't provide an official minified version.
          uris[:local ] = "#{['prototype', version].compact.join('-')}.js"
          uris[:remote] = "http#{'s' if use_ssl}://ajax.googleapis.com/ajax/libs/prototype/#{version}/prototype.js"
        when :scriptaculous
          # script.aculo.us currently doesn't provide an official minified version.
          uris[:local ] = "#{['scriptaculous', version].compact.join('-')}.js"
          uris[:remote] = "http#{'s' if use_ssl}://ajax.googleapis.com/ajax/libs/scriptaculous/#{version}/scriptaculous.js"
        when :mootools
          uris[:local ] = "#{['mootools', version].compact.join('-')}.min.js"
          uris[:remote] = "http#{'s' if use_ssl}://ajax.googleapis.com/ajax/libs/mootools/#{version}/mootools-yui-compressed.js"
        when :dojo
          uris[:local ] = "#{['dojo', version].compact.join('-')}.min.js"
          uris[:remote] = "http#{'s' if use_ssl}://ajax.googleapis.com/ajax/libs/dojo/#{version}/dojo/dojo.xd.js"
        when :swfobject
          uris[:local ] = "#{['swfobject', version].compact.join('-')}.min.js"
          uris[:remote] = "http#{'s' if use_ssl}://ajax.googleapis.com/ajax/libs/swfobject/#{version}/swfobject.js"
        when :yui
          uris[:local ] = "#{['yui', version].compact.join('-')}.min.js"
          uris[:remote] = "http#{'s' if use_ssl}://ajax.googleapis.com/ajax/libs/yui/#{version}/build/yuiloader/yuiloader-min.js"
        when :ext_core
          uris[:local ] = "#{['ext-core', version].compact.join('-')}.min.js"
          uris[:remote] = "http#{'s' if use_ssl}://ajax.googleapis.com/ajax/libs/ext-core/#{version}/ext-core.js"
        when :webfont
          uris[:local ] = "#{['webfont', version].compact.join('-')}.min.js"
          uris[:remote] = "http#{'s' if use_ssl}://ajax.googleapis.com/ajax/libs/webfont/#{version}/webfont.js"
        else nil # TODO: Write to log
        end

        # The remote URL can only be properly determined if the version number
        # is known; otherwise, discard.
        uris.delete(:remote) if version.blank?

        uris
      end

    end

  end

end

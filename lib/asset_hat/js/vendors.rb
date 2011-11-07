module AssetHat
  module JS
    # For working with supported 3rd-party JavaScript
    # plugin/framework/library vendors.
    module Vendors
      # A list of supported 3rd-party JavaScript plugin/vendor names.
      # Homepages:
      #
      # * Frameworks/libraries:
      #   * {Dojo}[http://dojotoolkit.org/]
      #   * {Ext Core}[http://extjs.com/products/extcore/]
      #   * {jQuery UI}[http://jqueryui.com/]
      #   * {jQuery}[http://jquery.com/]
      #   * {MooTools}[http://mootools.net/]
      #   * {Prototype}[http://www.prototypejs.org/]
      #   * {script.aculo.us}[http://script.aculo.us/]
      #   * {SWFObject}[http://code.google.com/p/swfobject/]
      #   * {WebFont Loader}[http://code.google.com/apis/webfonts/docs/webfont_loader.html]
      #   * {YUI}[http://developer.yahoo.com/yui/]
      # * Loaders:
      #   * {LABjs}[http://labjs.com]
      VENDORS_ON_GOOGLE_CDN = [
        :dojo,
        :ext_core,
        :jquery,
        :jquery_ui,
        :mootools,
        :prototype,
        :scriptaculous,
        :swfobject,
        :webfont,
        :yui
      ]
      VENDORS_ON_CDNJS = [
        :lab_js
      ]
      VENDORS = VENDORS_ON_GOOGLE_CDN + VENDORS_ON_CDNJS

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
      # [version] The vendor version, e.g., '1.6.0' for jQuery 1.6. By
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
          unless vendor_config.nil?
            src   = vendor_config['remote_ssl_url'] if use_ssl
            src ||= vendor_config['remote_url']
          end

          # Use default remote URL as fallback
          src ||= remote_src

          # Use local URL as final resort, even though the file doesn't
          # exist, in hopes that the app maintainer finds the 404 (or the
          # warning below) in the logs. This needs to be fixed in the app,
          # rather than relying on a CDN to dynamically provide the latest
          # stable vendor version.
          if src.blank?
            src = local_src
            Rails.logger.warn "\n\nAssetHat WARNING (#{Time.now}):\n" + %{
              Tried to reference the vendor JS `:#{vendor}`, but
              #{AssetHat.assets_dir(:js)}/#{local_src} couldn't be found, and
              couldn't use a remote fallback because no vendor version was
              given in #{AssetHat::RELATIVE_CONFIG_FILEPATH}.
            }.squish!
              # TODO: Create `AssetHat::Logger.warn`, etc. methods
          end
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
        when :lab_js
          uris[:local ] = "#{['LAB', version].compact.join('-')}.min.js"

          remote_host =
            if use_ssl
              'https://d3eee1nukb5wg.cloudfront.net/'
                # This must match the value in the cdnjs repo:
                # https://github.com/cdnjs/cdnjs/raw/master/https_location
                #
                # Amazon CloudFront doesn't support SSL, as discussed here:
                # - http://www.cdnjs.com/#IDComment130405257
                # - https://forums.aws.amazon.com/message.jspa?messageID=141951
                # As a result, the SSL certificate at <https://cdnjs.com> is
                # invalid. To work around this, we instead load assets via
                # cdnjs's CloudFront bucket ID. The bucket ID may change in
                # the future, so it should be synced with the host published
                # in the cdnjs repo, as noted above.
                #
                # For complete control over this, you can simply download the
                # vendor JS and host it on a server where you can maintain
                # SSL certificates.
            else
              'http://ajax.cdnjs.com'
            end
          uris[:remote] = "#{remote_host}/ajax/libs/labjs/#{version}/LAB.min.js"
        else nil # TODO: Write to log
        end

        # The remote URL can only be properly determined if the version number
        # is known; otherwise, discard.
        uris.delete(:remote) if version.blank?

        uris
      end

      # Usage (currently only supports LABjs):
      #
      #   AssetHat::JS::Vendors.loader_js :lab_js,
      #     :urls => ['/javascripts/app.js',
      #               'http://cdn.example.com/jquery.js']
      #
      # Returns a string of JS:
      #
      #   window.$LABinst=$LAB.
      #     script('/javascripts/app.js').wait().
      #     script('http://cdn.example.com/jquery.js').wait();
      def self.loader_js(loader, opts)
        return nil unless opts[:urls]

        case loader
        when :lab_js
          urls  = opts[:urls]
          lines = ['window.$LABinst=$LAB.']
          urls.each_with_index do |url, i|
            is_last = i >= urls.length - 1
            lines << "  script('#{url}').wait()#{is_last ? ';' : '.'}"
              # Use `wait()` for each script to load in parallel, but
              # preserve execution order by default. Alternatively, call
              # `$LAB.setOptions({AlwaysPreserveOrder:true})` at the start
              # of the chain, but if the list of bundles to include is short,
              # this may use even more bytes.
          end
          lines.join("\n")
        end
      end

    end

  end

end


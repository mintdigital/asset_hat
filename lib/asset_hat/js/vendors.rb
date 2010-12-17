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

      # Accepts an item from VENDORS, and returns the URL at which that vendor
      # asset can be found. The URL is either local (relative) or external
      # depending on the environment configuration. If external, the URL
      # points to {Google's CDN}[http://code.google.com/apis/ajaxlibs/].
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
        use_local = if defined?(Rails) && Rails.respond_to?(:application)
                      Rails.application.config.consider_all_requests_local
                    else # Rails 2.x
                      ActionController::Base.consider_all_requests_local
                    end
        use_ssl   = !!options[:ssl]
        version   = options[:version] || vendor_config['version'] rescue nil

        unless use_local
          src = vendor_config['remote_url'] rescue nil
          src = (vendor_config['remote_ssl_url'] rescue nil) if use_ssl
        end

        if src.blank?
          case vendor
          when :jquery
            src = use_local || version.blank? ?
              "#{['jquery', version].compact.join('-')}.min.js" :
              "http#{'s' if use_ssl}://ajax.googleapis.com/ajax/libs/jquery/#{version}/jquery.min.js"
          when :jquery_ui
            src = use_local || version.blank? ?
              "#{['jquery-ui', version].compact.join('-')}.min.js" :
              "http#{'s' if use_ssl}://ajax.googleapis.com/ajax/libs/jqueryui/#{version}/jquery-ui.min.js"
          when :prototype
            # Prototype currently doesn't provide an official minified version.
            src = use_local || version.blank? ?
              "#{['prototype', version].compact.join('-')}.js" :
              "http#{'s' if use_ssl}://ajax.googleapis.com/ajax/libs/prototype/#{version}/prototype.js"
          when :scriptaculous
            # script.aculo.us currently doesn't provide an official minified version.
            src = use_local || version.blank? ?
              "#{['scriptaculous', version].compact.join('-')}.js" :
              "http#{'s' if use_ssl}://ajax.googleapis.com/ajax/libs/scriptaculous/#{version}/scriptaculous.js"
          when :mootools
            src = use_local || version.blank? ?
              "#{['mootools', version].compact.join('-')}.min.js" :
              "http#{'s' if use_ssl}://ajax.googleapis.com/ajax/libs/mootools/#{version}/mootools-yui-compressed.js"
          when :dojo
            src = use_local || version.blank? ?
              "#{['dojo', version].compact.join('-')}.min.js" :
              "http#{'s' if use_ssl}://ajax.googleapis.com/ajax/libs/dojo/#{version}/dojo/dojo.xd.js"
          when :swfobject
            src = use_local || version.blank? ?
              "#{['swfobject', version].compact.join('-')}.min.js" :
              "http#{'s' if use_ssl}://ajax.googleapis.com/ajax/libs/swfobject/#{version}/swfobject.js"
          when :yui
            src = use_local || version.blank? ?
              "#{['yui', version].compact.join('-')}.min.js" :
              "http#{'s' if use_ssl}://ajax.googleapis.com/ajax/libs/yui/#{version}/build/yuiloader/yuiloader-min.js"
          when :ext_core
            src = use_local || version.blank? ?
              "#{['ext_core', version].compact.join('-')}.min.js" :
              "http#{'s' if use_ssl}://ajax.googleapis.com/ajax/libs/ext-core/#{version}/ext-core.js"
          when :webfont
            src = use_local || version.blank? ?
              "#{['webfont', version].compact.join('-')}.min.js" :
              "http#{'s' if use_ssl}://ajax.googleapis.com/ajax/libs/webfont/#{version}/webfont.js"
          else nil # TODO: Write to log
          end
        end

        src
      end
    end

  end

end

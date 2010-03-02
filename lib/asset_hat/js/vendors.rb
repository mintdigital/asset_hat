module AssetHat
  module JS
    module Vendors
      VENDORS = [:jquery, :jquery_ui, :prototype, :scriptaculous]

      def self.source_for(vendor, options={})
        vendor_config =
          AssetHat.config['js']['vendors'][vendor.to_s] rescue nil
        use_local = ActionController::Base.consider_all_requests_local
        version   = options[:version] || vendor_config['version'] rescue nil

        unless use_local
          src = vendor_config['remote_url'] rescue nil
        end

        if src.blank?
          case vendor
          when :jquery
            src = use_local || version.blank? ?
              "#{['jquery', version].compact.join('-')}.min.js" :
              "http://ajax.googleapis.com/ajax/libs/jquery/#{version}/jquery.min.js"
          when :jquery_ui
            src = use_local || version.blank? ?
              "#{['jquery-ui', version].compact.join('-')}.min.js" :
              "http://ajax.googleapis.com/ajax/libs/jqueryui/#{version}/jquery-ui.min.js"
          when :prototype
            # Prototype currently doesn't provide an official minified version.
            src = use_local || version.blank? ?
              "#{['prototype', version].compact.join('-')}.js" :
              "http://ajax.googleapis.com/ajax/libs/prototype/#{version}/prototype.js"
          when :scriptaculous
            # script.aculo.us currently doesn't provide an official minified version.
            src = use_local || version.blank? ?
              "#{['scriptaculous', version].compact.join('-')}.js" :
              "http://ajax.googleapis.com/ajax/libs/scriptaculous/#{version}/scriptaculous.js"
          else nil # TODO: Write to log
          end
        end

        src
      end
    end

  end

end

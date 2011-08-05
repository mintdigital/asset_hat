module AssetHat
  module JS
    module Vendors
      
      module Google
        def lib_name
          name.downcase
        end
        def local_uri(version, opts={})
          "#{[lib_name, version].compact.join('-')}.min.js"
        end
        def remote_uri(version, opts={})
          "http#{'s' if opts[:use_ssl]}" +
          "://ajax.googleapis.com/ajax/libs/#{lib_name}/#{version}/#{lib_name}.min.js"
        end
      end
      
      module Jquery
        extend Google
      end
      
      module JQueryUI
        extend Google
        def local_uri(version, opts={})
          "#{['jquery-ui', version].compact.join('-')}.min.js"
        end
        def remote_uri(version, opts={})
          "http#{'s' if opts[:use_ssl]}" +
          "://ajax.googleapis.com/ajax/libs/#{lib_name}/#{version}/jquery-ui.min.js"
        end
      end
      
      module Prototype
        extend Google
      end
      
      module Scriptaculous
        extend Google
      end
      
      module Mootools
        extend Google
        def self.remote_uri(version, opts={})
          "http#{'s' if opts[:use_ssl]}" +
          "://ajax.googleapis.com/ajax/libs/#{lib_name}/#{version}/mootools-yui-compressed.js"
        end
      end
      
      module Yui
        extend Google
        def self.remote_uri(version, opts={})
          "http#{'s' if opts[:use_ssl]}" +
          "://ajax.googleapis.com/ajax/libs/yui/#{version}/build/yuiloader/yuiloader-min.js"
        end
      end
    end
  end
end
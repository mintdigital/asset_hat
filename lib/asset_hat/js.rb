require 'jsmin'
  # - http://github.com/rgrove/jsmin
  # - http://gemcutter.org/gems/jsmin

module AssetHat
  module JS
    ENGINES = [:weak, :jsmin]
    VENDORS = [:jquery]
      # TODO: Support jQuery UI, Prototype, MooTools, etc.

    def self.min_filepath(filepath)
      AssetHat.min_filepath(filepath, 'js')
    end

    def self.minify(input_string, options={})
      options.reverse_merge!(:engine => :jsmin)

      engine = options[:engine].to_sym
      unless ENGINES.include?(engine)
        raise %Q{
          Unknown JS minification engine '#{engine}'.
          Allowed: #{ENGINES.map{ |e| "'#{e}'" }.join(', ')}
        }.strip.gsub(/\s+/, ' ') and return
      end

      AssetHat::JS::Engines.send(engine, input_string)
    end

    module Engines
      def self.weak(input_string)
        input   = StringIO.new(input_string)
        output  = StringIO.new

        input.each do |line|
          # Remove indentation and trailing whitespace
          line.strip!
          next if line.blank?

          # Skip single-line comments
          next if !(line =~ /^\/\//).nil?
          # TODO: Also skip single-line comments that began mid-line, but not
          #       inside a string or regex

          # TODO: Skip multi-line comments
          # - Should not strip from within a string or regex
          # - Should not strip comments that begin with `/*!` (e.g., licenses)

          output.write(line + "\n")
        end

        output.rewind
        output.read
      end

      def self.jsmin(input_string)
        JSMin.minify(input_string)
      end
    end # module Engines

    module Vendors
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
          else nil
          end
        end

        src
      end
    end # module Vendors

  end

end

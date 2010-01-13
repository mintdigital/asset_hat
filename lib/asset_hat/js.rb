module AssetHat
  module JS
    ENGINES = [:weak]
      # TODO: Add with a better minification engine (e.g., YUI, Closure)
      #       that won't require a significant change in coding style.

    def self.min_filepath(filepath)
      AssetHat::min_filepath(filepath, 'js')
    end

    def self.minify(input_string, options={})
      options.reverse_merge!(:engine => :weak)

      unless ENGINES.include?(options[:engine])
        raise %Q{
          Unknown JS minification engine "#{options[:engine]}".
          Allowed: #{ENGINES.map{ |e| ":#{e}" }.join(', ')}
        }.strip.gsub(/\s+/, ' ') and return
      end

      AssetHat::JS::Engines.send(options[:engine], input_string)
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
    end

  end

end

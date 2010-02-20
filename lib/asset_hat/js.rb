require 'jsmin'
  # - http://github.com/rgrove/jsmin
  # - http://gemcutter.org/gems/jsmin
require File.join(File.dirname(__FILE__), 'js', 'vendors')

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

  end

end

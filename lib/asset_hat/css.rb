require 'cssmin'

module AssetHat
  module CSS
    ENGINES = [:weak, :cssmin]

    def self.min_filepath(filepath)
      AssetHat.min_filepath(filepath, 'css')
    end

    def self.minify(input_string, options={})
      options.reverse_merge!(:engine => :cssmin)

      engine = options[:engine].to_sym
      unless ENGINES.include?(engine)
        raise %Q{
          Unknown CSS minification engine '#{engine}'.
          Allowed: #{ENGINES.map{ |e| "'#{e}'" }.join(', ')}
        }.strip.gsub(/\s+/, ' ') and return
      end

      AssetHat::CSS::Engines.send(engine, input_string)
    end

    def self.add_asset_commit_ids(css)
      css.gsub(/url[\s]*\((\/(images|htc)\/[^)]+)\)/) do |match|
        src = $1

        # Get absolute path
        filepath = File.join(ASSETS_DIR, src)

        # Convert to relative path
        filepath.sub!(/^#{FileUtils.pwd}#{File::SEPARATOR}/, '')

        commit_id = AssetHat.last_commit_id(filepath)
        commit_id.present? ? "url(#{src}?#{commit_id})" : "url(#{src})"
      end
    end

    def self.add_asset_hosts(css, asset_host)
      return if asset_host.blank?
      css.gsub(/url[\s]*\((\/(images|htc)\/[^)]+)\)/) do |match|
        src = $1
        "url(#{(asset_host =~ /%d/) ? asset_host % (src.hash % 4) : asset_host}#{src})"
      end
    end

    # Collection of swappable CSS minification engines.
    module Engines
      # Barebones CSS minification engine that only strips whitespace from the
      # start and end of every line, including linebreaks. For safety, doesn't
      # attempt to parse the CSS itself.
      def self.weak(input_string)
        input   = StringIO.new(input_string)
        output  = StringIO.new

        input.each do |line|
          # Remove indentation and trailing whitespace (including line breaks)
          line.strip!
          next if line.blank?

          output.write line
        end

        output.rewind
        output.read
      end

      # CSS minification engine that simply uses the CSSMin gem, a Ruby port
      # of Lecomte's YUI Compressor and Schlueter's PHP cssmin. Sources:
      # - http://github.com/rgrove/cssmin
      # - http://rubygems.org/gems/cssmin
      def self.cssmin(input_string)
        CSSMin.minify(input_string)
      end
    end

  end

end

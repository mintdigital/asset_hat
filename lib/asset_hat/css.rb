require 'cssmin'
  # - http://github.com/rgrove/cssmin
  # - http://gemcutter.org/gems/cssmin

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

    # def self.add_asset_mtimes(css)
    #   css.gsub(/url[\s]*\((\/(images|htc)\/[^)]+)\)/) do |match|
    #     src = $1
    #     mtime = File.mtime(File.join(Rails.public_path, src))
    #     "url(#{src}?#{mtime.to_i})"
    #   end
    # end

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

    module Engines
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

      def self.cssmin(input_string)
        CSSMin.minify(input_string)
      end
    end

  end

end

require File.join(File.dirname(__FILE__), '..', 'rails', 'init.rb')

module AssetHat
  def min_filepath(filepath, extension)
    filepath.sub(/([^\.]*).#{extension}$/, "\\1.min.#{extension}")
  end

  module CSS
    def minify(input_string)
      # TODO: Replace with a real minification engine, e.g., YUI, cssmin

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

    def add_css_asset_mtimes(css)
      css.gsub(/url[\s]*\((\/images\/[^)]+)\)/) do |match|
        mtime = File.mtime(File.join(Rails.public_path, $1))
        "url(#{$1}?#{mtime.to_i})"
      end
    end

    def add_css_asset_hosts(css, asset_host)
      return if asset_host.blank?
      css.gsub(/url[\s]*\((\/images\/[^)]+)\)/) do |match|
        source = $1
        "url(#{(asset_host =~ /%d/) ? asset_host % (source.hash % 4) : asset_host}#{source})"
      end
    end
  end

  module JS
    def minify(input_string)
      # TODO: Replace with a better minification engine (e.g., YUI, Closure)
      #       that won't require a significant change in coding style.

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

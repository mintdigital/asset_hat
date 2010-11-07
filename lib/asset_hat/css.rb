require 'cssmin'

module AssetHat
  # Methods for minifying and optimizing CSS.
  module CSS
    # A list of supported minification
    # <a href=CSS/Engines.html>engine</a> names.
    ENGINES = [:weak, :cssmin]

    # Returns the expected path for the minified version of a CSS asset:
    #
    #     AssetHat::CSS.min_filepath('public/stylesheets/bundles/application.css')
    #       # => 'public/stylesheets/bundles/application.min.css'
    def self.min_filepath(filepath)
      AssetHat.min_filepath(filepath, 'css')
    end

    # Accepts a string of CSS, and returns that CSS minified. Options:
    #
    # [engine]  Default is <code>:cssmin</code>; see
    #           <a href=CSS/Engines.html#method-c-cssmin>Engines.cssmin</a>.
    #           Allowed values are in ENGINES.
    def self.minify(input_string, options={})
      options.reverse_merge!(:engine => :cssmin)

      engine = options[:engine].to_sym
      unless ENGINES.include?(engine)
        raise %{
          Unknown CSS minification engine '#{engine}'.
          Allowed: #{ENGINES.map{ |e| "'#{e}'" }.join(', ')}
        }.strip.gsub(/\s+/, ' ') and return
      end

      AssetHat::CSS::Engines.send(engine, input_string).strip
    end

    # Given a string containing CSS, appends each referenced asset's last
    # commit ID to its URL, e.g.,
    # <code>background: url(/images/foo.png?ab12cd3)</code>. This enables
    # cache busting: If the user's browser has cached a copy of foo.png from a
    # previous deployment, this new URL forces the browser to ignore that
    # cache and request the latest version.
    def self.add_asset_commit_ids(css)
      sub_src = lambda do |match|
        src   = $1
        quote = src[0, 1]

        if %w[' "].include?(quote) && quote == src[-1, 1]
          src = src[1, src.length - 2]
        else
          quote = nil
        end

        # Get absolute path
        filepath = File.join(ASSETS_DIR, src)

        # Convert to relative path
        filepath.sub!(/^#{FileUtils.pwd}#{File::SEPARATOR}/, '')

        commit_id = AssetHat.last_commit_id(filepath)
        if commit_id.present?
          "url(#{quote}#{src}#{src =~ /\?/ ? '&' : '?'}#{commit_id}#{quote})"
        else
          "url(#{quote}#{src}#{quote})"
        end
      end

      # Match without quotes
      css.gsub!(/url[\s]*\((\/(images|htc)\/[^)'"]+)\)/, &sub_src)

      # Match with single/double quotes
      css.gsub!(/url[\s]*\(((['"])\/(images|htc)\/[^)]+\2)\)/, &sub_src)

      css
    end

    # Arguments:
    #
    # - A string containing CSS;
    # - A string containing the app's asset host, e.g.,
    #   'http\://cdn%d.example.com'. This value is typically taken from
    #   <code>config.action_controller.asset_host</code> in
    #   the app's <code>config/environments/production.rb</code>.
    #
    # An asset host is added to every image URL in the CSS, e.g.,
    # <code>background: url(http\://cdn2.example.com/images/foo.png)</code>;
    # if <code>%d</code> in the asset host, it is replaced with an arbitrary
    # number in 0-3, inclusive.
    #
    # Options:
    #
    # [ssl] Set to <code>true</code> to simulate a request via SSL. Defaults
    #       to <code>false</code>.
    def self.add_asset_hosts(css, asset_host, options={})
      return if asset_host.blank?

      options.reverse_merge!(:ssl => false)

      css.gsub(/url[\s]*\((\/images\/[^)]+)\)/) do |match|
        # N.B.: The `/htc/` directory is excluded because IE 6, by default,
        # refuses to run .htc files (e.g., TwinHelix's iepngfix.htc) from
        # other domains, including CDN subdomains.
        src = $1
        computed_asset_host = AssetHat.compute_asset_host(
          asset_host, src, options.slice(:ssl))
        "url(#{computed_asset_host}#{src})"
      end
    end

    # Swappable CSS minification engines. Each accepts and returns a string.
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

      # CSS minification engine that mostly uses the CSSMin gem, a Ruby port
      # of Lecomte's YUI Compressor and Schlueter's PHP cssmin.
      #
      # Sources:
      # - http://github.com/rgrove/cssmin
      # - http://rubygems.org/gems/cssmin
      def self.cssmin(input_string)
        output = CSSMin.minify(input_string)

        # Remove rules that have empty declaration blocks
        output.gsub!(/\}([^\}]+\{;\}){1,}/, '}')

        output
      end
    end

  end

end

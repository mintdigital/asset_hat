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
    # [engine]  Default is +cssmin+; see
    #           <a href=CSS/Engines.html#method-c-cssmin>Engines.cssmin</a>.
    #           Allowed values are in ENGINES.
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

    # Given a string containing CSS, appends each referenced asset's last
    # commit ID to its URL, e.g.,
    # <tt>background: url(/images/foo.png?ab12cd34e)</tt>. This enables cache
    # busting: If the user's browser has cached a copy of foo.png from a
    # previous deployment, this new URL forces the browser to ignore that
    # cache and request the latest version.
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

    # Arguments:
    #
    # - A string containing CSS;
    # - A string containing the app's asset host, e.g.,
    #   'http://assets%d.example.com'. This value is typically taken from
    #   <tt>config.action_controller.asset_host</tt> in
    #   the app's <tt>config/environments/production.rb</tt>.
    #
    # An asset host is added to every asset URL in the CSS, e.g.,
    # <tt>background: url(http://assets2.example.com/images/foo.png)</tt>;
    # if +%d+ in the asset host, it is replaced with an arbitrary number in
    # 0-3, inclusive.
    def self.add_asset_hosts(css, asset_host)
      return if asset_host.blank?
      css.gsub(/url[\s]*\((\/(images|htc)\/[^)]+)\)/) do |match|
        src = $1
        "url(#{(asset_host =~ /%d/) ? asset_host % (src.hash % 4) : asset_host}#{src})"
      end
    end

    # Swappable CSS minification engines.
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
      # of Lecomte's YUI Compressor and Schlueter's PHP cssmin.
      #
      # Sources:
      # - http://github.com/rgrove/cssmin
      # - http://rubygems.org/gems/cssmin
      def self.cssmin(input_string)
        CSSMin.minify(input_string)
      end
    end

  end

end

require 'test_helper'

class AssetHatHelperTest < ActionView::TestCase
  RAILS_ROOT = "#{File.dirname(__FILE__)}/.." unless defined?(RAILS_ROOT)

  context 'include_css' do
    context 'with caching enabled' do
      context 'with minified versions' do
        setup     { @asset_id = ENV['RAILS_ASSET_ID'] = '111' }
        teardown  { ENV['RAILS_ASSET_ID'] = nil }

        should 'include one file by name, and automatically use minified version' do
          output = include_css('foo', :cache => true)
          assert_equal css_tag("foo.min.css?#{@asset_id}"), output
        end

        should 'include one unminified file by name and extension' do
          output = include_css('foo.css', :cache => true)
          assert_equal css_tag("foo.css?#{@asset_id}"), output
        end

        should 'include one minified file by name and extension' do
          output = include_css('foo.min.css', :cache => true)
          assert_equal css_tag("foo.min.css?#{@asset_id}"), output
        end

        should 'include multiple files by name' do
          expected = %w[foo bar].map do |source|
            css_tag("#{source}.min.css?#{@asset_id}")
          end.join("\n")
          output = include_css('foo', 'bar', :cache => true)
          assert_equal expected, output
        end

        should 'include multiple files as a bundle' do
          bundle = 'css-bundle-1'
          output = include_css(:bundle => bundle, :cache => true)
          assert_equal css_tag("bundles/#{bundle}.min.css?#{@asset_id}"), output
        end
      end # context 'with minified versions'

      context 'without minified versions' do
        should 'include one file by name, and automatically use original version' do
          output = include_css('foo')
          assert_equal css_tag('foo.css'), output
        end
      end # context 'without minified versions'
    end # context 'with caching enabled'

    context 'with caching disabled' do
      should 'include one file by name, and automatically use original version' do
        output = include_css('foo', :cache => false)
        assert_equal css_tag('foo.css'), output
      end

      should 'include one unminified file by name and extension' do
        output = include_css('foo.css', :cache => false)
        assert_equal css_tag('foo.css'), output
      end

      should 'include multiple files by name' do
        expected = %w[foo bar.min].map { |src| css_tag("#{src}.css") }.join("\n")
        output = include_css('foo', 'bar.min', :cache => false)
        assert_equal expected, output
      end

      context 'with real bundle files' do
        setup do
          @asset_id = ENV['RAILS_ASSET_ID'] = '111'
          @config = AssetHat::config
        end
        teardown { ENV['RAILS_ASSET_ID'] = nil }

        should 'include a bundle as separate files' do
          bundle = 'css-bundle-1'
          expected = @config['css']['bundles'][bundle].map do |source|
            css_tag("#{source}.css?#{@asset_id}")
          end.join("\n")
          output = include_css(:bundle => bundle, :cache => false)
          assert_equal expected, output
        end

        should 'include multiple bundles as separate files' do
          bundles = [1,2,3].map { |i| "css-bundle-#{i}" }
          expected = bundles.map do |bundle|
            sources = @config['css']['bundles'][bundle]
            sources.map { |src| css_tag("#{src}.css?#{@asset_id}") }
          end.flatten.uniq.join("\n")
          output = include_css(:bundles => bundles, :cache => false)
          assert_equal expected, output
        end
      end # context 'with real bundle files'
    end # context 'with caching disabled'
  end # context 'include_css'

  context 'include_js' do
    context 'with caching enabled' do
      context 'with minified versions' do
        setup     { @asset_id = ENV['RAILS_ASSET_ID'] = '111' }
        teardown  { ENV['RAILS_ASSET_ID'] = nil }

        should 'include one file by name, and automatically use minified version' do
          output = include_js('jquery.some-plugin', :cache => true)
          assert_equal js_tag("jquery.some-plugin.min.js?#{@asset_id}"), output
        end

        should 'include one unminified file by name and extension' do
          output = include_js('jquery.some-plugin.js', :cache => true)
          assert_equal js_tag("jquery.some-plugin.js?#{@asset_id}"), output
        end

        should 'include one minified file by name and extension' do
          output = include_js('jquery.some-plugin.min.js', :cache => true)
          assert_equal js_tag("jquery.some-plugin.min.js?#{@asset_id}"), output
        end

        should 'include jQuery' do
          output = include_js(:jquery, :cache => true)
          assert_equal js_tag("jquery-1.3.2.min.js?#{@asset_id}"), output
        end

        should 'include multiple files by name' do
          expected = %w[foo jquery.bar].map do |source|
            js_tag("#{source}.min.js?#{@asset_id}")
          end.join("\n")
          output = include_js('foo', 'jquery.bar', :cache => true)
          assert_equal expected, output
        end

        should 'include multiple files as a bundle' do
          bundle = 'js-bundle-1'
          output = include_js(:bundle => bundle, :cache => true)
          assert_equal js_tag("bundles/#{bundle}.min.js?#{@asset_id}"), output
        end

        should 'include multiple bundles' do
          expected = %w[foo bar].map do |bundle|
            js_tag("bundles/#{bundle}.min.js?#{@asset_id}")
          end.join("\n")
          output = include_js(:bundles => %w[foo bar], :cache => true)
          assert_equal expected, output
        end
      end # context 'with minified versions'

      context 'without minified versions' do
        should 'include one file by name, and automatically use original version' do
          output = include_js('jquery.some-plugin', :cache => true)
          assert_equal js_tag('jquery.some-plugin.js'), output
        end
      end # context 'without minified versions'
    end # context 'with caching enabled'

    context 'with caching disabled' do
      should 'include one file by name, and automatically use original version' do
        output = include_js('foo', :cache => false)
        assert_equal js_tag('foo.js'), output
      end

      should 'include one unminified file by name and extension' do
        output = include_js('foo.js', :cache => false)
        assert_equal js_tag('foo.js'), output
      end

      should 'include one minified file by name and extension' do
        output = include_js('foo.min.js', :cache => false)
        assert_equal js_tag('foo.min.js'), output
      end

      should 'include multiple files by name' do
        expected = %w[foo bar.min].map { |src| js_tag("#{src}.js") }.join("\n")
        output = include_js('foo', 'bar.min', :cache => false)
        assert_equal expected, output
      end

      context 'with real bundle files' do
        setup do
          @asset_id = ENV['RAILS_ASSET_ID'] = '111'
          @config = AssetHat::config
        end
        teardown { ENV['RAILS_ASSET_ID'] = nil }

        should 'include a bundle as separate files' do
          bundle = 'js-bundle-1'
          sources = @config['js']['bundles'][bundle]
          expected = sources.map { |src| js_tag("#{src}.js?#{@asset_id}") }.join("\n")
          output = include_js(:bundle => bundle, :cache => false)
          assert_equal expected, output
        end

        should 'include multiple bundles as separate files' do
          bundles = [1,2,3].map { |i| "js-bundle-#{i}" }
          expected = bundles.map do |bundle|
            sources = @config['js']['bundles'][bundle]
            sources.map { |src| js_tag("#{src}.js?#{@asset_id}") }
          end.flatten.uniq.join("\n")
          output = include_js(:bundles => bundles, :cache => false)
          assert_equal expected, output
        end
      end # context 'with real bundle files'
    end # context 'with caching disabled'

  end # context 'include_js'



  private

  def css_tag(filename)
    %Q{<link href="/stylesheets/#{filename}" media="screen,projection" rel="stylesheet" type="text/css" />}
  end

  def js_tag(filename)
    %Q{<script src="/javascripts/#{filename}" type="text/javascript"></script>}
  end

end

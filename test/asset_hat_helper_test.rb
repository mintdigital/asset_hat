require 'test_helper'

class AssetHatHelperTest < ActionView::TestCase
  RAILS_ROOT = "#{File.dirname(__FILE__)}/.." unless defined?(RAILS_ROOT)

  context 'include_css' do
    context 'with caching enabled' do
      context 'with minified versions' do
        setup do
          @commit_id = '111'
          flexmock(AssetHat, :last_commit_id => @commit_id)
        end

        should 'include one file by name, and ' +
               'automatically use minified version' do
          flexmock(AssetHat, :asset_exists? => true)
          output = include_css('foo', :cache => true)
          assert_equal css_tag("foo.min.css?#{@commit_id}"), output
        end

        should 'include one unminified file by name and extension' do
          output = include_css('foo.css', :cache => true)
          assert_equal css_tag("foo.css?#{@commit_id}"), output
        end

        should 'include one minified file by name and extension' do
          output = include_css('foo.min.css', :cache => true)
          assert_equal css_tag("foo.min.css?#{@commit_id}"), output
        end

        should 'include multiple files by name' do
          flexmock(AssetHat, :asset_exists? => true)
          expected = %w[foo bar].map do |source|
            css_tag("#{source}.min.css?#{@commit_id}")
          end.join("\n")
          output = include_css('foo', 'bar', :cache => true)
          assert_equal expected, output
        end

        should 'include multiple files as a bundle' do
          bundle = 'css-bundle-1'
          output = include_css(:bundle => bundle, :cache => true)
          assert_equal(
            css_tag("bundles/#{bundle}.min.css?#{@commit_id}"), output)
        end

        context 'via SSL' do
          setup do
            @request = ActionController::TestRequest.new
            flexmock(controller, :request => @request)
            flexmock(@request, :ssl? => true)
            flexmock(@controller, :request => @request)
            assert @controller.request.ssl?,
              'Precondition: Request should use SSL'
          end

          should 'include multiple files as a bundle' do
            bundle = 'css-bundle-1'
            output = include_css(:bundle => bundle, :cache => true)
            assert_equal(
              css_tag("bundles/ssl/#{bundle}.min.css?#{@commit_id}"), output)
          end
        end # context 'via SSL'

      end # context 'with minified versions'

      context 'without minified versions' do
        should 'include one file by name, and ' +
               'automatically use original version' do
          output = include_css('foo')
          assert_equal css_tag('foo.css'), output
        end
      end # context 'without minified versions'
    end # context 'with caching enabled'

    context 'with caching disabled' do
      should 'include one file by name, and ' +
             'automatically use original version' do
        output = include_css('foo', :cache => false)
        assert_equal css_tag('foo.css'), output
      end

      should 'include one unminified file by name and extension' do
        output = include_css('foo.css', :cache => false)
        assert_equal css_tag('foo.css'), output
      end

      should 'include multiple files by name' do
        expected = %w[foo bar.min].
          map { |src| css_tag("#{src}.css") }.join("\n")
        output = include_css('foo', 'bar.min', :cache => false)
        assert_equal expected, output
      end

      context 'with real bundle files' do
        setup do
          @asset_id = ENV['RAILS_ASSET_ID'] = '222'
          @config = AssetHat.config
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
    setup do
      @request = ActionController::TestRequest.new
      flexmock(controller, :request => @request)
    end

    context 'with caching enabled' do
      context 'with minified versions' do
        setup do
          @commit_id = '111'
          flexmock(AssetHat,
            :last_commit_id => @commit_id,
            :last_bundle_commit_id => @commit_id
          )
        end

        should 'include one file by name, and ' +
               'automatically use minified version' do
          flexmock(AssetHat, :asset_exists? => true)
          output = include_js('jquery.some-plugin', :cache => true)
          assert_equal js_tag("jquery.some-plugin.min.js?#{@commit_id}"),
            output
        end

        should 'include one unminified file by name and extension' do
          output = include_js('jquery.some-plugin.js', :cache => true)
          assert_equal js_tag("jquery.some-plugin.js?#{@commit_id}"), output
        end

        should 'include one minified file by name and extension' do
          output = include_js('jquery.some-plugin.min.js', :cache => true)
          assert_equal(
            js_tag("jquery.some-plugin.min.js?#{@commit_id}"), output)
        end

        context 'with vendors' do
          should 'know where to find each vendor file' do
            AssetHat::JS::VENDORS.each do |vendor|
              assert include_js(vendor, :cache => true).present?
            end
          end

          should 'include jQuery and jQuery UI' do
            flexmock(AssetHat, :config => @original_config)
            [:jquery, :jquery_ui].each do |vendor|
              output = include_js(vendor, :cache => true)
              assert_equal(
                js_tag("#{vendor.to_s.dasherize}.min.js?#{@commit_id}"),
                output)
            end
          end

          should 'include Prototype and script.aculo.us' do
            [:prototype, :scriptaculous].each do |vendor|
              output = include_js(vendor, :cache => true)
              assert_equal js_tag("#{vendor}.js?#{@commit_id}"), output
                # N.B.: Including only the regular, not minified, version
            end
          end

          context 'with remote requests via SSL' do
            should 'include JS via https://ajax.googleapis.com' do
              AssetHat::JS::VENDORS.each do |vendor|
                AssetHat.html_cache[:js] = {}
                helper_opts = {:version => '1', :cache => true}

                flexmock_teardown
                flexmock(AssetHat, :cache? => true)
                flexmock(ActionController::Base,
                  :consider_all_requests_local => false)
                flexmock(@request, :ssl? => true)
                flexmock(@controller, :request => @request)
                assert @controller.request.ssl?,
                  'Precondition: Request should use SSL'

                https_html = include_js(vendor, helper_opts.dup)
                assert_match(
                  %r{src="https://ajax\.googleapis\.com/}, https_html)
                assert_equal 1, AssetHat.html_cache[:js].size
                assert_equal https_html, AssetHat.html_cache[:js].first[1],
                  'SSL HTML should be cached'
                http_cache_key = AssetHat.html_cache[:js].first[0]

                flexmock_teardown
                flexmock(AssetHat, :cache? => true)
                flexmock(ActionController::Base,
                  :consider_all_requests_local => false)
                flexmock(@request, :ssl? => false)
                flexmock(@controller, :request => @request)
                assert !@controller.request.ssl?,
                  'Precondition: Request should not use SSL'
                assert_equal 1, AssetHat.html_cache[:js].size
                assert_equal https_html,
                  AssetHat.html_cache[:js][http_cache_key],
                  'SSL HTML should be still be cached'

                http_html = include_js(vendor, helper_opts)
                assert_match(
                  %r{src="http://ajax\.googleapis\.com/},
                  http_html,
                  'Should not use same cached HTML for SSL and non-SSL')
                assert_equal 2, AssetHat.html_cache[:js].size
                assert_equal https_html,
                  AssetHat.html_cache[:js][http_cache_key],
                  'SSH HTML should still be cached'
                assert_equal http_html,
                  AssetHat.html_cache[:js].except(http_cache_key).first[1],
                  'Non-SSL HTML should be cached'
              end
            end
          end # context 'via SSL'
        end # context 'with vendor JS'

        should 'include jQuery by version via helper option' do
          version = '1.4.1'
          output = include_js(:jquery, :version => version, :cache => true)
          assert_equal(
            js_tag("jquery-#{version}.min.js?#{@commit_id}"), output)
        end

        context 'with a mock config' do
          setup do
            version = '1.4.1'
            config = AssetHat.config
            config['js']['vendors'] = {
              'jquery' => {
                'version' => version,
                'remote_url' => 'http://example.com/cdn/jquery.min.js',
                'remote_ssl_url' => 'https://secure.example.com/cdn/jquery.min.js'
              }
            }
            flexmock(AssetHat, :config => config)
          end

          should 'include jQuery by version via config file' do
            version = AssetHat.config['js']['vendors']['jquery']['version']
            assert_equal(
              js_tag("jquery-#{version}.min.js?#{@commit_id}"),
              include_js(:jquery, :cache => true)
            )
          end

          context 'with remote requests' do
            setup do
              flexmock(ActionController::Base,
                :consider_all_requests_local => false)
            end

            should 'use specified remote URL for jQuery' do
              src = AssetHat.config['js']['vendors']['jquery']['remote_url']
              assert_equal(
                %Q{<script src="#{src}" type="text/javascript"></script>},
                include_js(:jquery, :cache => true)
              )
            end

            should 'use specified remote SSL URL for jQuery' do
              flexmock(ActionController::Base,
                :consider_all_requests_local => false)
              flexmock(@request, :ssl? => true)
              src =
                AssetHat.config['js']['vendors']['jquery']['remote_ssl_url']

              assert_equal(
                %Q{<script src="#{src}" type="text/javascript"></script>},
                include_js(:jquery, :cache => true)
              )
            end
          end # context 'with remote requests'
        end # context 'with a mock config'

        should 'include multiple files by name' do
          flexmock(AssetHat, :asset_exists? => true)
          expected = %w[foo jquery.bar].map do |source|
            js_tag("#{source}.min.js?#{@commit_id}")
          end.join("\n")
          output = include_js('foo', 'jquery.bar', :cache => true)
          assert_equal expected, output
        end

        should 'include multiple files as a bundle' do
          bundle = 'js-bundle-1'
          output = include_js(:bundle => bundle, :cache => true)
          assert_equal(
            js_tag("bundles/#{bundle}.min.js?#{@commit_id}"), output)
        end

        should 'include multiple bundles' do
          flexmock(AssetHat, :asset_exists? => true)
          expected = %w[foo bar].map do |bundle|
            js_tag("bundles/#{bundle}.min.js?#{@commit_id}")
          end.join("\n")
          output = include_js(:bundles => %w[foo bar], :cache => true)
          assert_equal expected, output
        end

      end # context 'with minified versions'

      context 'without minified versions' do
        should 'include one file by name, and ' +
               'automatically use original version' do
          output = include_js('jquery.some-plugin', :cache => true)
          assert_equal js_tag('jquery.some-plugin.js'), output
        end
      end # context 'without minified versions'
    end # context 'with caching enabled'

    context 'with caching disabled' do
      should 'include one file by name, and ' +
             'automatically use original version' do
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
        expected = %w[foo bar.min].
          map { |src| js_tag("#{src}.js") }.join("\n")
        output = include_js('foo', 'bar.min', :cache => false)
        assert_equal expected, output
      end

      context 'with real bundle files' do
        setup do
          @asset_id = ENV['RAILS_ASSET_ID'] = '222'
          @config = AssetHat.config
        end
        teardown { ENV['RAILS_ASSET_ID'] = nil }

        should 'include a bundle as separate files' do
          bundle = 'js-bundle-1'
          sources = @config['js']['bundles'][bundle]
          expected = sources.
            map { |src| js_tag("#{src}.js?#{@asset_id}") }.join("\n")
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
    %Q{
      <link href="/stylesheets/#{filename}"
            media="screen,projection" rel="stylesheet" type="text/css" />
    }.strip.gsub(/\s+/, ' ')
  end

  def js_tag(filename)
    %Q{<script src="/javascripts/#{filename}" type="text/javascript"></script>}
  end

end

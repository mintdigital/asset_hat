require 'test_helper'

class AssetHatHelperTest < ActionView::TestCase
  RAILS_ROOT = "#{File.dirname(__FILE__)}/.." unless defined?(RAILS_ROOT)

  context 'include_css' do
    setup { flexmock_rails_app }

    context 'with caching enabled' do
      context 'with minified versions' do
        setup do
          @commit_id = '111'
          flexmock(AssetHat).should_receive(:last_commit_id => @commit_id).
            by_default
        end

        should 'include one file by name, and ' +
               'automatically use minified version' do
          flexmock(AssetHat, :asset_exists? => true)
          expected_html = css_tag("foo.min.css?#{@commit_id}")
          expected_path =
            AssetHat.assets_path(:css) + "/foo.min.css?#{@commit_id}"

          assert_equal expected_html, include_css('foo', :cache => true)
          assert_equal expected_path, include_css('foo', :cache => true,
                                        :only_url => true)
        end

        should 'include one unminified file by name and extension' do
          expected_html = css_tag("foo.css?#{@commit_id}")
          expected_path =
            AssetHat.assets_path(:css) + "/foo.css?#{@commit_id}"

          assert_equal expected_html, include_css('foo.css', :cache => true)
          assert_equal expected_path, include_css('foo.css', :cache => true,
                                        :only_url => true)
        end

        should 'include one minified file by name and extension' do
          expected_html = css_tag("foo.min.css?#{@commit_id}")
          expected_path =
            AssetHat.assets_path(:css) + "/foo.min.css?#{@commit_id}"

          assert_equal expected_html,
            include_css('foo.min.css', :cache => true)
          assert_equal expected_path,
            include_css('foo.min.css', :cache => true, :only_url => true)
        end

        should 'include multiple files by name' do
          flexmock(AssetHat, :asset_exists? => true)

          sources = %w[foo bar]
          expected_html = sources.map do |source|
            css_tag("#{source}.min.css?#{@commit_id}")
          end.join("\n")
          expected_paths = sources.map do |source|
            AssetHat.assets_path(:css) + "/#{source}.min.css?#{@commit_id}"
          end

          assert_equal expected_html,
            include_css('foo', 'bar', :cache => true)
          assert_equal expected_paths,
            include_css('foo', 'bar', :cache => true, :only_url => true)
        end

        should 'include multiple files as a bundle' do
          bundle = 'css-bundle-1'
          expected_html = css_tag("bundles/#{bundle}.min.css?#{@commit_id}")
          expected_path =
            AssetHat.bundles_path(:css) + "/#{bundle}.min.css?#{@commit_id}"

          assert_equal expected_html,
            include_css(:bundle => bundle, :cache => true)
          assert_equal expected_path,
            include_css(:bundle => bundle, :cache => true, :only_url => true)
        end

        context 'via SSL' do
          setup do
            @request = test_request
            flexmock(@controller).should_receive(:request => @request).
              by_default
            flexmock(@controller.request).should_receive(:ssl? => true).
              by_default
            assert @controller.request.ssl?,
              'Precondition: Request should use SSL'
          end

          should 'include multiple files as a SSL bundle' do
            flexmock(AssetHat, :ssl_asset_host_differs? => true)
            bundle = 'css-bundle-1'
            expected_html =
              css_tag("bundles/ssl/#{bundle}.min.css?#{@commit_id}")
            expected_path = AssetHat.bundles_path(:css, :ssl => true) +
              "/#{bundle}.min.css?#{@commit_id}"

            assert_equal expected_html,
              include_css(:bundle => bundle, :cache => true)
            assert_equal expected_path,
              include_css(:bundle => bundle, :cache => true,
                :only_url => true)
          end

          should 'use non-SSL CSS if SSL/non-SSL asset hosts are the same' do
            flexmock(AssetHat, :ssl_asset_host_differs? => false)
            bundle = 'css-bundle-1'
            expected_html = css_tag("bundles/#{bundle}.min.css?#{@commit_id}")
            expected_path = AssetHat.bundles_path(:css) +
              "/#{bundle}.min.css?#{@commit_id}"

            assert_equal expected_html,
              include_css(:bundle => bundle, :cache => true)
            assert_equal expected_path,
              include_css(:bundle => bundle, :cache => true,
                :only_url => true)
          end
        end # context 'via SSL'

      end # context 'with minified versions'

      context 'without minified versions' do
        should 'include one file by name, and ' +
               'automatically use original version' do
          expected_html = css_tag('foo.css')
          expected_path = AssetHat.assets_path(:css) + '/foo.css'

          assert_equal expected_html, include_css('foo')
          assert_equal expected_path, include_css('foo', :only_url => true)
        end
      end # context 'without minified versions'
    end # context 'with caching enabled'

    context 'with caching disabled' do
      should 'include one file by name, and ' +
             'automatically use original version' do
        expected_html = css_tag('foo.css')
        expected_path = AssetHat.assets_path(:css) + '/foo.css'

        assert_equal expected_html, include_css('foo', :cache => false)
        assert_equal expected_path, include_css('foo', :cache => false,
                                      :only_url => true)
      end

      should 'include one unminified file by name and extension' do
        expected_html = css_tag('foo.css')
        expected_path = AssetHat.assets_path(:css) + '/foo.css'

        assert_equal expected_html, include_css('foo.css', :cache => false)
        assert_equal expected_path, include_css('foo.css', :cache => false,
                                      :only_url => true)
      end

      should 'include multiple files by name' do
        sources = %w[foo bar.min]
        expected_html =
          sources.map { |source| css_tag("#{source}.css") }.join("\n")
        expected_paths = sources.map do |source|
          AssetHat.assets_path(:css) + "/#{source}.css"
        end

        assert_equal expected_html,
          include_css('foo', 'bar.min', :cache => false)
        assert_equal expected_paths,
          include_css('foo', 'bar.min', :cache => false, :only_url => true)
      end

      context 'with real bundle files' do
        setup do
          @asset_id = ENV['RAILS_ASSET_ID'] = '222'
          @config = AssetHat.config
        end
        teardown { ENV['RAILS_ASSET_ID'] = nil }

        should 'include a bundle as separate files' do
          bundle = 'css-bundle-1'
          bundle_filenames = @config['css']['bundles'][bundle]
          expected_html = bundle_filenames.map do |source|
            css_tag("#{source}.css?#{@asset_id}")
          end.join("\n")
          expected_paths = bundle_filenames.map do |source|
            AssetHat.assets_path(:css) + "/#{source}.css?#{@asset_id}"
          end

          assert_equal expected_html,
            include_css(:bundle => bundle, :cache => false)
          assert_equal expected_paths,
            include_css(:bundle => bundle, :cache => false, :only_url => true)
        end

        should 'include a bundle as separate files ' +
               'with a symbol bundle name' do
          bundle = 'css-bundle-1'
          expected = @config['css']['bundles'][bundle].map { |source|
            css_tag("#{source}.css?#{@asset_id}")
          }.join("\n")
          output = include_css(:bundle => bundle.to_sym, :cache => false)
          assert_equal expected, output
        end

        should 'include multiple bundles as separate files' do
          bundles = [1,2].map { |i| "css-bundle-#{i}" }
          expected_html = bundles.map { |bundle|
            sources = @config['css']['bundles'][bundle]
            sources.map { |src| css_tag("#{src}.css?#{@asset_id}") }
          }.flatten.uniq.join("\n")
          expected_paths = bundles.map do |bundle|
            sources = @config['css']['bundles'][bundle]
            sources.map do |src|
              AssetHat.assets_path(:css) + "/#{src}.css?#{@asset_id}"
            end
          end.flatten.uniq

          assert_equal expected_html,
            include_css(:bundles => bundles, :cache => false)
          assert_equal expected_paths,
            include_css(:bundles => bundles, :cache => false,
              :only_url => true)
        end

        should 'include named files and bundles together' do
          bundles = ['css-bundle-2']
          expected_html = css_tag("css-file-1-1.css?#{@asset_id}") + "\n" +
            bundles.map do |bundle|
              sources = @config['css']['bundles'][bundle]
              sources.map { |src| css_tag("#{src}.css?#{@asset_id}") }
            end.flatten.uniq.join("\n")
          expected_paths = ["/stylesheets/css-file-1-1.css?#{@asset_id}"] +
            bundles.map do |bundle|
              sources = @config['css']['bundles'][bundle]
              sources.map do |src|
                AssetHat.assets_path(:css) + "/#{src}.css?#{@asset_id}"
              end
            end.flatten.uniq

          assert_equal expected_html,
            include_css('css-file-1-1', :bundles => bundles, :cache => false)
          assert_equal expected_paths,
            include_css('css-file-1-1', :bundles => bundles, :cache => false,
              :only_url => true)
        end
      end # context 'with real bundle files'
    end # context 'with caching disabled'
  end # context 'include_css'

  context 'include_js' do
    setup do
      flexmock_rails_app
      @request = test_request
      flexmock(@controller).should_receive(:request => @request).by_default
    end

    context 'with caching enabled' do
      context 'with minified versions' do
        setup do
          @commit_id = '111'
          flexmock(AssetHat).should_receive(
            :last_commit_id        => @commit_id,
            :last_bundle_commit_id => @commit_id
          ).by_default
        end

        should 'include one file by name, and ' +
               'automatically use minified version' do
          flexmock(AssetHat, :asset_exists? => true)
          expected_html = js_tag("jquery.some-plugin.min.js?#{@commit_id}")
          expected_path = AssetHat.assets_path(:js) +
            "/jquery.some-plugin.min.js?#{@commit_id}"

          assert_equal expected_html,
            include_js('jquery.some-plugin', :cache => true)
          assert_equal expected_path,
            include_js('jquery.some-plugin', :cache => true,
              :only_url => true)
        end

        should 'include one unminified file by name and extension' do
          filename = 'jquery.some-plugin.js'
          expected_html = js_tag("#{filename}?#{@commit_id}")
          expected_path =
            AssetHat.assets_path(:js) + "/#{filename}?#{@commit_id}"

          assert_equal expected_html, include_js(filename, :cache => true)
          assert_equal expected_path, include_js(filename, :cache => true,
                                        :only_url => true)
        end

        should 'include one minified file by name and extension' do
          filename = 'jquery.some-plugin.min.js'
          expected_html = js_tag("#{filename}?#{@commit_id}")
          expected_path =
            AssetHat.assets_path(:js) + "/#{filename}?#{@commit_id}"

          assert_equal expected_html, include_js(filename, :cache => true)
          assert_equal expected_path, include_js(filename, :cache => true,
                                        :only_url => true)
        end

        context 'with vendors' do
          should 'know where to find each vendor file' do
            AssetHat::JS::VENDORS.each do |vendor|
              assert include_js(vendor, :cache => true).present?
              assert include_js(vendor, :cache => true,
                                        :only_url => true).present?
            end
          end

          should 'include jQuery and jQuery UI via local vendor files' do
            [:jquery, :jquery_ui].each do |vendor|
              vendor_filename = "#{vendor.to_s.dasherize}.min.js"
              flexmock(AssetHat).should_receive(:asset_exists?).
                with(vendor_filename, :js).and_return(true)

              expected_html = js_tag("#{vendor_filename}?#{@commit_id}")
              expected_path = AssetHat.assets_path(:js) +
                                "/#{vendor_filename}?#{@commit_id}"

              assert_equal expected_html, include_js(vendor, :cache => true)
              assert_equal expected_path, include_js(vendor, :cache => true,
                                            :only_url => true)
            end
          end

          should 'include Prototype and script.aculo.us ' +
                 'via local vendor files' do
            [:prototype, :scriptaculous].each do |vendor|
              vendor_filename = "#{vendor}.js"
              flexmock(AssetHat).should_receive(:asset_exists?).
                with(vendor_filename, :js).and_return(true)

              expected_html = js_tag("#{vendor_filename}?#{@commit_id}")
                # N.B.: Including only the regular, not minified, version
              expected_path = AssetHat.assets_path(:js) +
                                "/#{vendor_filename}?#{@commit_id}"

              assert_equal expected_html, include_js(vendor, :cache => true)
              assert_equal expected_path, include_js(vendor, :cache => true,
                                            :only_url => true)
            end
          end

          should 'not use a remote URL fallback if version is unknown' do
            output = include_js(:jquery, :cache => true)
            assert_equal js_tag("jquery.min.js?#{@commit_id}"), output
          end

          context 'with remote requests via SSL' do
            should 'include vendor JS via Google CDN' do
              AssetHat::JS::Vendors::VENDORS_ON_GOOGLE_CDN.each do |vendor|
                AssetHat.html_cache[:js] = {}
                helper_opts = {:version => '1', :cache => true}

                # Setup
                flexmock_teardown
                flexmock_rails_app
                flexmock(AssetHat,
                  :cache? => true,
                  :consider_all_requests_local? => false
                )

                # Test inclusion via SSL
                flexmock(@controller.request, :ssl? => true)
                assert @controller.request.ssl?,
                  'Precondition: Request should use SSL'
                https_html = include_js(vendor, helper_opts.dup)
                assert_match(
                  %r{src="https://ajax\.googleapis\.com/}, https_html)
                assert_equal 1, AssetHat.html_cache[:js].size
                assert_equal https_html,
                  AssetHat.html_cache[:js].to_a.first[1],
                  'SSL HTML should be cached'

                # Re-setup
                flexmock_teardown
                flexmock_rails_app
                flexmock(AssetHat,
                  :cache? => true,
                  :consider_all_requests_local? => false
                )

                # Test caching of SSL inclusion HTML
                flexmock(@controller.request, :ssl? => false)
                http_cache_key = AssetHat.html_cache[:js].to_a.first[0]
                assert !@controller.request.ssl?,
                  'Precondition: Request should not use SSL'
                assert_equal 1, AssetHat.html_cache[:js].size
                assert_equal https_html,
                  AssetHat.html_cache[:js][http_cache_key],
                  'SSL HTML should be still be cached'

                # Test inclusion, and caching of inclusion HTML, via non-SSL
                http_html = include_js(vendor, helper_opts.dup)
                assert_match(
                  %r{src="http://ajax\.googleapis\.com/},
                  http_html,
                  'Should not use same cached HTML for SSL and non-SSL')
                assert_equal 2, AssetHat.html_cache[:js].size
                assert_equal https_html,
                  AssetHat.html_cache[:js][http_cache_key],
                  'SSH HTML should still be cached'
                assert_equal http_html,
                  AssetHat.html_cache[:js].except(http_cache_key).
                    to_a.first[1],
                  'Non-SSL HTML should be cached'
              end
            end

            should 'get vendor URLs pointing to Google CDN' do
              AssetHat::JS::Vendors::VENDORS_ON_GOOGLE_CDN.each do |vendor|
                AssetHat.html_cache[:js] = {}
                helper_opts = {:version => '1', :cache => true}

                # Setup
                flexmock_teardown
                flexmock_rails_app
                flexmock(AssetHat,
                  :cache? => true,
                  :consider_all_requests_local? => false
                )

                # Test SSL URL and URL caching
                flexmock(@controller.request, :ssl? => true)
                assert @controller.request.ssl?,
                  'Precondition: Request should use SSL'
                https_url = include_js(vendor,
                  helper_opts.dup.merge(:only_url => true))
                assert_equal 1, AssetHat.html_cache[:js].size
                assert_match %r{^https://ajax\.googleapis\.com/}, https_url

                # Re-setup
                flexmock_teardown
                flexmock_rails_app
                flexmock(AssetHat,
                  :cache? => true,
                  :consider_all_requests_local? => false
                )

                # Test non-SSL URL and URL caching
                flexmock(@controller.request, :ssl? => false)
                assert !@controller.request.ssl?,
                  'Precondition: Request should not use SSL'
                http_url = include_js(vendor,
                  helper_opts.dup.merge(:only_url => true))
                assert_equal 2, AssetHat.html_cache[:js].size
                assert_match %r{^http://ajax\.googleapis\.com/}, http_url
              end
            end
          end # context 'with remote requests via SSL'
        end # context 'with vendor JS'

        context 'with a mock config containing a version number' do
          setup do
            @vendor_version = '1.6.1'
            config = AssetHat.config
            config['js']['vendors'] = {
              'jquery' => {'version' => @vendor_version}
            }
            flexmock(AssetHat).should_receive(:config => config).by_default
          end

          should 'include local copy of vendor with version in config file' do
            vendor_filename = "jquery-#{@vendor_version}.min.js"
            flexmock(AssetHat).should_receive(:asset_exists?).
              with(vendor_filename, :js).and_return(true)

            expected_html = js_tag("#{vendor_filename}?#{@commit_id}")
            expected_path =
              AssetHat.assets_path(:js) + "/#{vendor_filename}?#{@commit_id}"

            assert_equal expected_html, include_js(:jquery, :cache => true)
            assert_equal expected_path, include_js(:jquery, :cache => true,
                                          :only_url => true)
          end

          should 'include local copy of vendor with ' +
                 'custom version in helper options' do
            custom_version  = '1.3.2'
            vendor_filename = "jquery-#{custom_version}.min.js"
            flexmock(AssetHat).should_receive(:asset_exists?).
              with(vendor_filename, :js).and_return(true)

            assert_equal(
              js_tag("#{vendor_filename}?#{@commit_id}"),
              include_js(:jquery, :version => custom_version, :cache => true))
          end

          context 'with local requests but no local copy of vendor file' do
            setup do
              # Mock for version from config file:
              flexmock(AssetHat).should_receive(:asset_exists?).
                with("jquery-#{@vendor_version}.min.js", :js).
                and_return(false).by_default

              # Mock for version from helper options:
              @custom_vendor_version = '1.3.2'
              flexmock(AssetHat).should_receive(:asset_exists?).
                with("jquery-#{@custom_vendor_version}.min.js", :js).
                and_return(false).by_default

              assert AssetHat.consider_all_requests_local?, 'Precondition'
            end

            should 'fall back to default remote vendor URL ' +
                   'with version in config file' do
              src = "http://ajax.googleapis.com/ajax/libs/jquery/" +
                    "#{@vendor_version}/jquery.min.js"

              assert_equal(
                %{<script src="#{src}" type="text/javascript"></script>},
                include_js(:jquery, :cache => true))
            end

            should 'fall back to default remote vendor URL ' +
                   'with custom version in helper options' do
              src = "http://ajax.googleapis.com/ajax/libs/jquery/" +
                    "#{@custom_vendor_version}/jquery.min.js"

              assert_equal(
                %{<script src="#{src}" type="text/javascript"></script>},
                include_js(:jquery, :version => @custom_vendor_version,
                                    :cache   => true))
            end

            should 'fall back to default remote vendor SSL URL ' +
                   'with version in config file' do
              flexmock(@controller.request, :ssl? => true)
              src = "https://ajax.googleapis.com/ajax/libs/jquery/" +
                    "#{@vendor_version}/jquery.min.js"

              assert_equal(
                %{<script src="#{src}" type="text/javascript"></script>},
                include_js(:jquery, :cache => true))
            end

            should 'fall back to default remote vendor SSL URL ' +
                   'with custom version in helper options' do
              flexmock(@controller.request, :ssl? => true)
              src = "https://ajax.googleapis.com/ajax/libs/jquery/" +
                    "#{@custom_vendor_version}/jquery.min.js"

              assert_equal(
                %{<script src="#{src}" type="text/javascript"></script>},
                include_js(:jquery, :version => @custom_vendor_version,
                                    :cache   => true))
            end

          end # context 'with local requests but no local copy of vendor file'
        end # context 'with a mock config containing a version number'

        context 'with a mock config containing custom CDN URLs' do
          setup do
            @vendor_version = '1.6.1'
            config = AssetHat.config
            config['js']['vendors'] = {
              'jquery' => {
                'version'        => @vendor_version,
                'remote_url'     => 'http://example.com/cdn/' +
                                    "jquery-#{@vendor_version}.min.js",
                'remote_ssl_url' => 'https://secure.example.com/cdn/' +
                                    "jquery-#{@vendor_version}.min.js"
              }
            }
            flexmock(AssetHat).should_receive(:config => config).by_default
          end

          context 'with local requests but no local copy of vendor file' do
            setup do
              flexmock(AssetHat).should_receive(:asset_exists?).
                with("jquery-#{@vendor_version}.min.js", :js).
                and_return(false).by_default
              assert AssetHat.consider_all_requests_local?, 'Precondition'
            end

            should 'fall back to configured remote vendor URL' do
              src = AssetHat.config['js']['vendors']['jquery']['remote_url']
              assert_equal(
                %{<script src="#{src}" type="text/javascript"></script>},
                include_js(:jquery, :cache => true))
            end

            should 'fall back to configured remote vendor SSL URL' do
              flexmock(@controller.request, :ssl? => true)
              src =
                AssetHat.config['js']['vendors']['jquery']['remote_ssl_url']

              assert_equal(
                %{<script src="#{src}" type="text/javascript"></script>},
                include_js(:jquery, :cache => true)
              )
            end
          end # context 'with local requests but no local copy of vendor file'

          context 'with remote requests' do
            setup do
              flexmock(AssetHat).
                should_receive(:consider_all_requests_local? => false)
              assert !AssetHat.consider_all_requests_local?, 'Precondition'
            end

            should 'use specified remote URL for vendor' do
              src = AssetHat.config['js']['vendors']['jquery']['remote_url']
              expected_html =
                %{<script src="#{src}" type="text/javascript"></script>}
              expected_path = src

              assert_equal expected_html, include_js(:jquery, :cache => true)
              assert_equal expected_path, include_js(:jquery, :cache => true,
                                            :only_url => true)
            end

            should 'use specified remote SSL URL for vendor' do
              flexmock(@controller.request, :ssl? => true)
              src =
                AssetHat.config['js']['vendors']['jquery']['remote_ssl_url']
              expected_html =
                %{<script src="#{src}" type="text/javascript"></script>}
              expected_path = src

              assert_equal expected_html, include_js(:jquery, :cache => true)
              assert_equal expected_path, include_js(:jquery, :cache => true,
                                            :only_url => true)
            end
          end # context 'with remote requests'

        end # context 'with a mock config containing custom CDN URLs'

        should 'include multiple files by name' do
          flexmock(AssetHat, :asset_exists? => true)
          sources = %w[foo jquery.plugin]
          expected_html = sources.map do |source|
            js_tag("#{source}.min.js?#{@commit_id}")
          end.join("\n")
          expected_paths = sources.map do |source|
            AssetHat.assets_path(:js) + "/#{source}.min.js?#{@commit_id}"
          end

          assert_equal expected_html,
            include_js('foo', 'jquery.plugin', :cache => true)
          assert_equal expected_paths,
            include_js('foo', 'jquery.plugin', :cache => true,
              :only_url => true)
        end

        should 'include multiple files as a bundle' do
          bundle   = 'js-bundle-1'
          filename = "#{bundle}.min.js"
          expected_html = js_tag("bundles/#{filename}?#{@commit_id}")
          expected_path =
            AssetHat.bundles_path(:js) + "/#{filename}?#{@commit_id}"

          assert_equal expected_html,
            include_js(:bundle => bundle, :cache => true)
          assert_equal expected_path,
            include_js(:bundle => bundle, :cache => true, :only_url => true)
        end

        should 'include multiple bundles' do
          flexmock(AssetHat, :asset_exists? => true)
          bundles = %w[foo bar]
          expected_html = bundles.map do |bundle|
            js_tag("bundles/#{bundle}.min.js?#{@commit_id}")
          end.join("\n")
          expected_paths = bundles.map do |bundle|
            AssetHat.bundles_path(:js) + "/#{bundle}.min.js?#{@commit_id}"
          end

          assert_equal expected_html,
            include_js(:bundles => bundles, :cache => true)
          assert_equal expected_paths,
            include_js(:bundles => bundles, :cache => true, :only_url => true)
        end

        context 'via SSL' do
          setup do
            @request = test_request
            flexmock(@controller).should_receive(:request => @request).
              by_default
            flexmock(@controller.request).should_receive(:ssl? => true).
              by_default
            assert @controller.request.ssl?,
              'Precondition: Request should use SSL'
          end

          should 'use non-SSL JS if SSL/non-SSL asset hosts differ' do
            flexmock(AssetHat, :ssl_asset_host_differs? => true)
            bundle = 'js-bundle-1'
            expected_html = js_tag("bundles/#{bundle}.min.js?#{@commit_id}")
            expected_path =
              AssetHat.bundles_path(:js) + "/#{bundle}.min.js?#{@commit_id}"

            assert_equal expected_html,
              include_js(:bundle => bundle, :cache => true)
            assert_equal expected_path,
              include_js(:bundle => bundle, :cache => true, :only_url => true)
          end

          should 'use non-SSL JS if SSL/non-SSL asset hosts are the same' do
            flexmock(AssetHat, :ssl_asset_host_differs? => false)
            bundle = 'js-bundle-1'
            expected_html = js_tag("bundles/#{bundle}.min.js?#{@commit_id}")
            expected_path =
              AssetHat.bundles_path(:js) + "/#{bundle}.min.js?#{@commit_id}"

            assert_equal expected_html,
              include_js(:bundle => bundle, :cache => true)
            assert_equal expected_path,
              include_js(:bundle => bundle, :cache => true, :only_url => true)
          end
        end # context 'via SSL'
      end # context 'with minified versions'

      context 'without minified versions' do
        should 'include one file by name, and ' +
               'automatically use original version' do
          source = 'jquery.some-plugin'
          expected_html = js_tag("#{source}.js")
          expected_path = AssetHat.assets_path(:js) + "/#{source}.js"

          assert_equal expected_html, include_js(source, :cache => true)
          assert_equal expected_path, include_js(source, :cache => true,
                                        :only_url => true)
        end
      end # context 'without minified versions'
    end # context 'with caching enabled'

    context 'with caching disabled' do
      should 'include one file by name, and ' +
             'automatically use original version' do
        source = 'foo'
        expected_html = js_tag("#{source}.js")
        expected_path = AssetHat.assets_path(:js) + "/#{source}.js"

        assert_equal expected_html, include_js(source, :cache => true)
        assert_equal expected_path, include_js(source, :cache => true,
                                      :only_url => true)
      end

      should 'include one unminified file by name and extension' do
        filename = 'foo.js'
        expected_html = js_tag(filename)
        expected_path = AssetHat.assets_path(:js) + "/#{filename}"

        assert_equal expected_html, include_js(filename, :cache => true)
        assert_equal expected_path, include_js(filename, :cache => true,
                                      :only_url => true)
      end

      should 'include one minified file by name and extension' do
        filename = 'foo.min.js'
        expected_html = js_tag(filename)
        expected_path = AssetHat.assets_path(:js) + "/#{filename}"

        assert_equal expected_html, include_js(filename, :cache => true)
        assert_equal expected_path, include_js(filename, :cache => true,
                                      :only_url => true)
      end

      should 'include multiple files by name' do
        sources = %w[foo bar.min]
        expected_html = sources.map do |source|
          js_tag("#{source}.js")
        end.join("\n")
        expected_paths = sources.map do |source|
          AssetHat.assets_path(:js) + "/#{source}.js"
        end

        assert_equal expected_html,
          include_js('foo', 'bar.min', :cache => false)
        assert_equal expected_paths,
          include_js('foo', 'bar.min', :cache => false, :only_url => true)
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
          expected_html = sources.map do |source|
            js_tag("#{source}.js?#{@asset_id}")
          end.join("\n")
          expected_paths = sources.map do |source|
            AssetHat.assets_path(:js) + "/#{source}.js?#{@asset_id}"
          end

          assert_equal expected_html,
            include_js(:bundle => bundle, :cache => false)
          assert_equal expected_paths,
            include_js(:bundle => bundle, :cache => false, :only_url => true)
        end

        should 'include a bundle as separate files ' +
               'with a symbol bundle name' do
          bundle   = 'js-bundle-1'
          sources  = @config['js']['bundles'][bundle]
          expected = sources.
            map { |src| js_tag("#{src}.js?#{@asset_id}") }.join("\n")
          output = include_js(:bundle => bundle.to_sym, :cache => false)
          assert_equal expected, output
        end

        should 'include multiple bundles as separate files' do
          bundles = [1,2].map { |i| "js-bundle-#{i}" }
          expected_html = bundles.map { |bundle|
            sources = @config['js']['bundles'][bundle]
            sources.map { |src| js_tag("#{src}.js?#{@asset_id}") }
          }.flatten.uniq.join("\n")
          expected_paths = bundles.map do |bundle|
            sources = @config['js']['bundles'][bundle]
            sources.map do |src|
              AssetHat.assets_path(:js) + "/#{src}.js?#{@asset_id}"
            end
          end.flatten.uniq

          assert_equal expected_html,
            include_js(:bundles => bundles, :cache => false)
          assert_equal expected_paths,
            include_js(:bundles => bundles, :cache => false,
              :only_url => true)
        end

        should 'include vendors, named files and bundles together' do
          bundles = ['js-bundle-2']
          expected_html =
            js_tag("jquery.min.js?#{@asset_id}") + "\n" +
            js_tag("js-file-1-1.js?#{@asset_id}") + "\n" +
            bundles.map do |bundle|
              sources = @config['js']['bundles'][bundle]
              sources.map { |src| js_tag("#{src}.js?#{@asset_id}") }
            end.flatten.uniq.join("\n")
          expected_paths =
            [ "/javascripts/jquery.min.js?#{@asset_id}",
              "/javascripts/js-file-1-1.js?#{@asset_id}" ] +
            bundles.map do |bundle|
              sources = @config['js']['bundles'][bundle]
              sources.map do |src|
                AssetHat.assets_path(:js) + "/#{src}.js?#{@asset_id}"
              end
            end.flatten.uniq

          assert_equal expected_html,
            include_js(:jquery, 'js-file-1-1', :bundles => bundles,
              :cache => false)
          assert_equal expected_paths,
            include_js(:jquery, 'js-file-1-1', :bundles => bundles,
              :cache => false, :only_url => true)
        end
      end # context 'with real bundle files'
    end # context 'with caching disabled'

    context 'with LABjs' do
      should 'render with default config and basic URL arguments' do
        urls      = [ '/javascripts/foo.js',
                      'http://cdn.example.com/bar.js' ]
        expected  = %{<script src="/javascripts/LAB.min.js" } +
                      %{type="text/javascript"></script>\n}
        expected << %{<script type="text/javascript">\n}
        expected << %{window.$LABinst=$LAB.\n}
        expected << %{  script('#{urls.first}').wait().\n}
        expected << %{  script('#{urls.second}').wait();\n}
        expected << %{</script>}

        assert_equal expected,
          include_js('foo', urls.second, :loader => :lab_js)
      end

      context 'with LABjs version config, vendor, and multiple bundles' do
        setup do
          @config = AssetHat.config
          @config['js']['vendors'] = {
            'jquery' => {'version' => '1.6.1'},
            'lab_js' => {'version' => '1.2.0'}
          }
          flexmock(AssetHat).should_receive(:config => @config).by_default

          @asset_id = ENV['RAILS_ASSET_ID'] = ''
          flexmock(AssetHat).should_receive(
            :asset_exists?  => false,
            :last_commit_id => ''
          ).by_default

          @jquery_version = @config['js']['vendors']['jquery']['version']
          @lab_js_version = @config['js']['vendors']['lab_js']['version']
        end
        teardown { ENV['RAILS_ASSET_ID'] = nil }

        context 'with local requests' do
          should 'render with caching disabled' do
            loader_filename = "LAB-#{@lab_js_version}.min.js"
            vendor_filename = "jquery-#{@jquery_version}.min.js"

            flexmock(AssetHat).should_receive(:asset_exists?).
              with(loader_filename, :js).and_return(true)
            flexmock(AssetHat).should_receive(:asset_exists?).
              with(vendor_filename, :js).and_return(true)
            assert AssetHat.asset_exists?(vendor_filename, :js),
              'Precondition'

            expected =  %{<script src="/javascripts/#{loader_filename}" } +
                          %{type="text/javascript"></script>\n}
            expected << %{<script type="text/javascript">\n}
            expected << "window.$LABinst=$LAB.\n"
            expected << "  script('/javascripts/#{vendor_filename}').wait().\n"
            expected << "  script('/javascripts/foo.js').wait().\n"
            expected << "  script('/javascripts/js-file-1-1.js').wait().\n"
            expected << "  script('/javascripts/js-file-1-2.js').wait().\n"
            expected << "  script('/javascripts/js-file-1-3.js').wait().\n"
            expected << "  script('/javascripts/js-file-2-1.js').wait().\n"
            expected << "  script('/javascripts/js-file-2-2.js').wait().\n"
            expected << "  script('/javascripts/js-file-2-3.js').wait();\n"
            expected << '</script>'

            assert_equal expected, include_js(:jquery, 'foo',
                                    :bundles => %w[js-bundle-1 js-bundle-2],
                                    :loader  => :lab_js)
          end

          should 'render with caching disabled and remote vendor ' +
                 'if local loader vendor is missing' do
            loader_filename = "LAB-#{@lab_js_version}.min.js"
            vendor_filename = "jquery-#{@jquery_version}.min.js"
            loader_url      = 'http://ajax.cdnjs.com/ajax/libs/labjs/' +
                                @lab_js_version + '/LAB.min.js'

            flexmock(AssetHat).should_receive(:asset_exists?).
              with(loader_filename, :js).and_return(false)
            flexmock(AssetHat).should_receive(:asset_exists?).
              with(vendor_filename, :js).and_return(true)
            assert AssetHat.asset_exists?(vendor_filename, :js),
              'Precondition'

            expected =  %{<script src="#{loader_url}" } +
                          %{type="text/javascript"></script>\n}
            expected << %{<script type="text/javascript">\n}
            expected << "window.$LABinst=$LAB.\n"
            expected << "  script('/javascripts/#{vendor_filename}').wait().\n"
            expected << "  script('/javascripts/foo.js').wait();\n"
            expected << '</script>'

            assert_equal expected,
              include_js(:jquery, 'foo', :loader => :lab_js)
          end
        end # context 'with local requests'

        context 'with remote requests' do
          setup do
            flexmock(AssetHat, :consider_all_requests_local? => false)
          end

          should 'render with caching enabled and remote vendors' do
            lab_js_url = 'http://ajax.cdnjs.com/ajax/libs/labjs/' +
                          @lab_js_version + '/LAB.min.js'
            jquery_url = 'http://ajax.googleapis.com/ajax/libs/jquery/' +
                          @jquery_version + '/jquery.min.js'

            expected =  %{<script src="#{lab_js_url}" } +
                          %{type="text/javascript"></script>\n}
            expected << %{<script type="text/javascript">\n}
            expected << "window.$LABinst=$LAB.\n"
            expected << "  script('#{jquery_url}').wait().\n"
            expected << "  script('/javascripts/foo.js').wait().\n"
            expected << "  script('/javascripts/" +
                            "bundles/js-bundle-1.min.js').wait().\n"
            expected << "  script('/javascripts/" +
                            "bundles/js-bundle-2.min.js').wait();\n"
            expected << '</script>'

            assert_equal expected, include_js(:jquery, 'foo',
                                    :bundles => %w[js-bundle-1 js-bundle-2],
                                    :loader  => :lab_js,
                                    :cache   => true)
          end
        end # context 'with remote requests'
      end # context 'with LABjs version config, vendor, and multiple bundles'
    end # context 'with LABjs'

  end # context 'include_js'

  should 'compute public asset paths' do
    flexmock_rails_app

    assert_equal '/stylesheets/foo.css', asset_path(:css, 'foo')
    assert_equal '/stylesheets/bundles/foo.min.css',
      asset_path(:css, 'bundles/foo.min.css')

    assert_equal '/javascripts/foo.js', asset_path(:js, 'foo')
    assert_equal '/javascripts/bundles/foo.min.js',
      asset_path(:js, 'bundles/foo.min.js')
  end



  private

  def css_tag(filename)
    %{
      <link href="/stylesheets/#{filename}"
            media="screen,projection" rel="stylesheet" type="text/css" />
    }.strip.gsub(/\s+/, ' ')
  end

  def js_tag(filename)
    %{<script src="/javascripts/#{filename}" type="text/javascript"></script>}
  end

  def flexmock_rails_app
    # Creates just enough hooks for a dummy Rails app.
    flexmock(Rails,
      :application => flexmock('dummy_app', :env_defaults => {}),
      :logger      => flexmock('dummy_logger', :warn => nil)
    )

    if defined?(config) # Rails 3.x
      config.assets_dir = AssetHat::ASSETS_DIR
    end

    flexmock(AssetHat).should_receive(:consider_all_requests_local? => true).
      by_default
  end

  # def flexmock_rails_app_config(opts)
  #   flexmock(Rails.application.config, opts)  # Rails 3.x
  #   flexmock(ActionController::Base, opts)    # Rails 2.x
  # end

  def test_request
    if defined?(ActionDispatch) # Rails 3.x
      ActionDispatch::TestRequest.new
    else # Rails 2.x
      ActionController::TestRequest.new
    end
  end

end

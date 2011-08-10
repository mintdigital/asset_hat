require 'test_helper'

class AssetHatTest < ActiveSupport::TestCase
  context 'AssetHat' do
    should 'know where to find/store assets in the file system' do
      assert_equal 'public/stylesheets', AssetHat.assets_dir(:css)
      assert_equal 'public/javascripts', AssetHat.assets_dir(:js)

      assert_equal 'bundles',     AssetHat.bundles_dir
      assert_equal 'bundles/ssl', AssetHat.bundles_dir(:ssl => true)
      assert_equal 'public/stylesheets/bundles', AssetHat.bundles_dir(:css)
      assert_equal 'public/javascripts/bundles', AssetHat.bundles_dir(:js)
      assert_equal 'public/stylesheets/bundles/ssl',
        AssetHat.bundles_dir(:css, :ssl => true)
      assert_equal 'public/javascripts/bundles/ssl',
        AssetHat.bundles_dir(:js, :ssl => true)
    end

    should 'know whether the config file needs to be generated' do
      flexmock(File).should_receive(:exists?).
        with(AssetHat::CONFIG_FILEPATH).and_return(false)

      assert_raise RuntimeError do
        AssetHat.config
      end
    end

    should 'know where to find assets via a URL' do
      assert_equal '/stylesheets', AssetHat.assets_path(:css)
      assert_equal '/javascripts', AssetHat.assets_path(:js)

      assert_equal '/stylesheets/bundles', AssetHat.bundles_path(:css)
      assert_equal '/stylesheets/bundles/ssl',
        AssetHat.bundles_path(:css, :ssl => true)
      assert_equal '/javascripts/bundles', AssetHat.bundles_path(:js)
      assert_equal '/javascripts/bundles/ssl',
        AssetHat.bundles_path(:js, :ssl => true)
    end

    context 'with caching enabled' do
      setup do
        flexmock(AssetHat, :cache? => true)
      end

      should 'memoize config' do
        AssetHat.config
        flexmock(YAML).should_receive(:load).never
        3.times { AssetHat.config }
      end
    end # context 'with caching enabled'

    context 'with caching disabled' do
      setup do
        flexmock(AssetHat, :cache? => false)
      end

      should 'not memoize config' do
        AssetHat.config
        flexmock(YAML).should_receive(:load).times(3)
        3.times { AssetHat.config }
      end
    end # context 'with caching disabled'

    should 'recognize existing assets' do
      assert  AssetHat.asset_exists?('css-file-1-1.css', :css)
      assert !AssetHat.asset_exists?('non-existent-css', :css)
      assert  AssetHat.asset_exists?('js-file-1-1.js',   :js)
      assert !AssetHat.asset_exists?('non-existent-js',  :js)
    end

    should "return a bundle's filenames" do
      assert_equal  %w[css-file-1-1 css-file-1-2 css-file-1-3],
                    AssetHat.bundle_filenames('css-bundle-1', :css)
    end

    should "return a bundle's filepaths" do
      expected = [1,2,3].map { |i| "public/stylesheets/css-file-1-#{i}.css" }
      assert_equal expected, AssetHat.bundle_filepaths('css-bundle-1', :css)
    end

    context 'with asset host' do
      should 'compute asset host from a String' do
        asset_host = 'http://cdn%d.example.com'
        flexmock(ActionController::Base, :asset_host => asset_host)
        assert_match /http:\/\/cdn\d\.example\.com/,
          AssetHat.compute_asset_host(asset_host, 'x.png')
      end

      should 'compute asset host from a Proc' do
        asset_host = Proc.new do |source, request|
          if request.ssl?
            "#{request.protocol}ssl.cdn#{source.hash % 4}.example.com"
          else
            "#{request.protocol}cdn#{source.hash % 4}.example.com"
          end
        end
        flexmock(ActionController::Base, :asset_host => asset_host)

        assert_match /http:\/\/cdn\d\.example\.com/,
          AssetHat.compute_asset_host(asset_host, 'x.png')
        assert_match /https:\/\/ssl\.cdn\d\.example\.com/,
          AssetHat.compute_asset_host(asset_host, 'x.png', :ssl => true)
      end

      should 'know that asset host is same between SSL and non-SSL URLs' do
        asset_host = 'http://cdn%d.example.com'
        flexmock(ActionController::Base, :asset_host => asset_host)
        assert !AssetHat.ssl_asset_host_differs?
      end

      should 'know that asset host differs between SSL and non-SSL URLs' do
        asset_host = Proc.new do |source, request|
          if request.ssl?
            "#{request.protocol}ssl.cdn#{source.hash % 4}.example.com"
          else
            "#{request.protocol}cdn#{source.hash % 4}.example.com"
          end
        end
        flexmock(ActionController::Base, :asset_host => asset_host)
        assert AssetHat.ssl_asset_host_differs?
      end
    end # context 'with asset host'
  end # context 'AssetHat'

  context 'AssetHat::CSS' do
    should 'return path to minified file' do
      assert_equal  'foo/bar/baz.min.css',
                    AssetHat::CSS.min_filepath('foo/bar/baz.css')
    end

    should 'return path to minified file with MD5 fingerprint' do
      fingerprint = 'a1b2c3'
      assert_equal  "foo/bar/baz-#{fingerprint}.min.css",
                    AssetHat::CSS.min_filepath('foo/bar/baz.css',
                      :fingerprint => fingerprint)
    end

    should 'add image asset commit IDs' do
      commit_id = 111
      flexmock(AssetHat, :last_commit_id => commit_id)
      flexmock(Rails, :public_path => '')

      # No/single/double quotes:
      ['', "'", '"'].each do |quote|
        img = '/images/foo.png'
        assert_equal(
          "p{background:url(#{quote}#{img}?#{commit_id}#{quote})}",
          AssetHat::CSS.add_asset_commit_ids(
            "p{background:url(#{quote}#{img}#{quote})}")
        )

        img = '/images/?id=foo.png'
        assert_equal(
          "p{background:url(#{quote}#{img}&#{commit_id}#{quote})}",
          AssetHat::CSS.add_asset_commit_ids(
            "p{background:url(#{quote}#{img}#{quote})}")
        )
      end

      # Mismatched quotes (should remain untouched):
      %w[
        '/images/foo.png
        '/images/?id=foo.png
        /images/foo.png'
        /images/?id=foo.png'
        "/images/foo.png
        "/images/?id=foo.png
        /images/foo.png"
        /images/?id=foo.png"
        '/images/foo.png"
        '/images/?id=foo.png"
        "/images/foo.png'
        "/images/?id=foo.png'
      ].each do |bad_url|
        assert_equal "p{background:url(#{bad_url})}",
          AssetHat::CSS.add_asset_commit_ids("p{background:url(#{bad_url})}")
      end
    end

    should 'add .htc asset commit IDs' do
      commit_id = 111
      flexmock(AssetHat, :last_commit_id => commit_id)
      flexmock(Rails, :public_path => '')

      assert_equal  "p{background:url(/htc/iepngfix.htc?#{commit_id})}",
                    AssetHat::CSS.add_asset_commit_ids(
                      "p{background:url(/htc/iepngfix.htc)}")
      assert_equal  "p{background:url(/htc/?id=iepngfix&#{commit_id})}",
                    AssetHat::CSS.add_asset_commit_ids(
                      "p{background:url(/htc/?id=iepngfix)}")
    end

    should 'add image asset hosts' do
      asset_host       = 'http://cdn%d.example.com'
      asset_host_regex = 'http://cdn\d\.example\.com'

      # No/single/double quotes:
      ['', "'", '"'].each do |quote|
        img = '/images/foo.png'
        assert_match(
          Regexp.new("^p\\{background:url\\(#{quote}" +
            "#{asset_host_regex}#{Regexp.escape(img)}#{quote}\\)\\}$"),
          AssetHat::CSS.add_asset_hosts(
            "p{background:url(#{quote}#{img}#{quote})}", asset_host)
        )
      end

      # Mismatched quotes (should remain untouched):
      %w[
        '/images/foo.png
        /images/foo.png'
        "/images/foo.png
        /images/foo.png"
        '/images/foo.png"
        "/images/foo.png'
      ].each do |bad_url|
        assert_equal "p{background:url(#{bad_url})}",
          AssetHat::CSS.add_asset_hosts("p{background:url(#{bad_url})}",
                                        asset_host)
      end
    end

    should 'not add .htc asset hosts' do
      asset_host = 'http://media%d.example.com'
      assert_match(
        /^p\{background:url\(\/htc\/iepngfix.htc\)\}$/,
        AssetHat::CSS.add_asset_hosts(
          'p{background:url(/htc/iepngfix.htc)}', asset_host)
      )
    end

    context 'when minifying' do
      setup do
        @input = %{
          .foo { width: 1px; }
          .bar {}
          .baz{  width  :  2px;  }
          .qux {}
          .quux { }
          .corge {/* ! */}
        }
      end

      context 'with cssmin engine' do
        should 'remove rules that have empty declaration blocks' do
          assert_equal '.foo{width:1px;}.baz{width:2px;}',
            AssetHat::CSS.minify(@input, :engine => :cssmin)
        end
      end
    end # context 'when minifying'

  end # context 'AssetHat::CSS'

  context 'AssetHat::JS' do
    should 'return path to minified file' do
      assert_equal  'foo/bar/baz.min.js',
                    AssetHat::JS.min_filepath('foo/bar/baz.js')
    end

    should 'return path to minified file with MD5 fingerprint' do
      fingerprint = 'a1b2c3'
      assert_equal  "foo/bar/baz-#{fingerprint}.min.js",
                    AssetHat::JS.min_filepath('foo/bar/baz.js',
                      :fingerprint => fingerprint)
    end

    context 'with minifying' do
      should 'minify if a string ends with a comment and no line break' do
        input = 'foo(); // bar'
        assert_equal 'foo();', AssetHat::JS.minify(input, :engine => :jsmin)
      end
    end # context 'with minifying'
  end # context 'AssetHat::JS'

  context 'AssetHat::Fingerprint' do
    should 'return the fingerprint for a string' do
      assert_match /[a-f0-9]{32}/,
        AssetHat::Fingerprint.for_string('application')
    end

    should 'return the fingerprint for a file' do
      assert_match /[a-f0-9]{32}/,
        AssetHat::Fingerprint.for_filepath(File.join(
          'public', 'stylesheets', 'css-file-1-1.css'
        ))
    end

    should 'return the fingerprint for a bundle' do
      AssetHat::TYPES.each do |type|
        bundle_name = AssetHat.config[type.to_s]['bundles'].keys.first
        assert bundle_name.present?, %{
          Precondition: The #{type.to_s.upcase} bundle
          `#{bundle_name}` should exist.
        }.squish!

        assert_match /[a-f0-9]{32}/,
          AssetHat::Fingerprint.for_bundle(bundle_name, type.to_sym)

        flexmock(AssetHat::Fingerprint).should_receive(:for_string).never
        assert AssetHat::Fingerprint.for_bundle(bundle_name, type.to_sym),
          'Should memoize fingerprint from previous call'
        flexmock_teardown
      end
    end
  end # context 'AssetHat::Fingerprint'

end

require 'test_helper'

class AssetHatTest < ActiveSupport::TestCase
  context 'AssetHat::CSS' do
    should 'return path to minified file' do
      assert_equal  'foo/bar/baz.min.css',
                    AssetHat::CSS::min_filepath('foo/bar/baz.css')
    end
  end # context 'AssetHat::CSS'

  context 'AssetHat::JS' do
    should 'return path to minified file' do
      assert_equal  'foo/bar/baz.min.js',
                    AssetHat::JS::min_filepath('foo/bar/baz.js')
    end
  end # context 'AssetHat::JS'

  should "return a bundle's filenames" do
    assert_equal  %w[css-file-1-1 css-file-1-2 css-file-1-3],
                  AssetHat::bundle_filenames('css-bundle-1', 'css')
  end
end

require 'rubygems'
require 'test/unit'
require 'active_support'
require 'action_controller'
require 'action_view/test_case'

require 'shoulda'
require 'asset_hat'
require 'flexmock/test_unit'
Dir[File.join(File.dirname(__FILE__), %w[.. app helpers *])].each { |f| require f }



ActionController::Base.perform_caching = false

unless defined?(Rails)
  # Enable `Rails.env.test?`, `Rails.env.development?`, etc.
  module Rails
    class << self
      def env ; ActiveSupport::StringInquirer.new('test') ; end
    end
  end
end

class ActionView::TestCase
  teardown :clear_html_cache

  def clear_html_cache
    AssetHat.html_cache = {}
  end
end

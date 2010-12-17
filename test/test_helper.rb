require 'rubygems'
require 'test/unit'
require 'active_support'
require 'action_controller'
require 'action_view/test_case'

require 'shoulda'
require 'flexmock/test_unit'
require 'asset_hat'
require 'asset_hat_helper'



ActionController::Base.perform_caching = false

unless defined?(Rails)
  module Rails
    class << self
      # Enable `Rails.env.test?`, `Rails.env.development?`, etc.
      def env; ActiveSupport::StringInquirer.new('test'); end
    end
  end
end

class ActionView::TestCase
  teardown :clear_html_cache

  def clear_html_cache
    AssetHat.clear_html_cache
  end
end

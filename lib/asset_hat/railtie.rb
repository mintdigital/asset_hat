require 'asset_hat'
require 'asset_hat_helper'
require 'rails'

module AssetHat
  class Railtie < Rails::Railtie #:nodoc:
    initializer 'asset_hat.action_view' do |app|
      require 'asset_hat/initializers/action_view'
    end

    initializer 'asset_hat.cache_last_commit_ids' do |app|
      require 'asset_hat/initializers/cache_last_commit_ids'
    end

    rake_tasks do
      load 'tasks/asset_hat.rake'
    end
  end
end

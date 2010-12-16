require 'asset_hat'
require 'asset_hat_helper'
require 'rails'

module AssetHat
  class Railtie < Rails::Railtie #:nodoc:
    initializer 'asset_hat.action_view' do |app|
      ActionView::Base.send(:include, ::AssetHatHelper)
    end

    initializer 'asset_hat.cache_last_commit_ids' do |app|
      AssetHat.cache_last_commit_ids unless defined?(::IRB)
    end

    rake_tasks do
      load 'tasks/asset_hat.rake'
    end
  end
end

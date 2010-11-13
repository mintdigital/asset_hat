::ActionView::Base.send(:include, AssetHatHelper)
AssetHat.cache_last_commit_ids unless defined?(::IRB)

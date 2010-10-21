::ActionView::Base.send(:include, AssetHatHelper)
AssetHat.cache_last_commit_ids if defined?(::IRB) != 'constant'

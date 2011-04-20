# Add the code below to your app's unicorn.conf.rb or similar so that assets'
# commit IDs are precached only once by the Unicorn master, then propagated
# out to workers. (Otherwise, each worker will precache commit IDs, which
# wastes resources.) More on configuring Unicorn:
# http://unicorn.bogomips.org/Unicorn/Configurator.html

before_fork do |server, worker|
  AssetHat.cache_last_commit_ids if defined?(AssetHat)
end

::ActionView::Base.send(:include, AssetHatHelper)

# Precalculate (and memoize) asset commit IDs
AssetHat::TYPES.each do |type|
  next if AssetHat.config[type.to_s].blank? ||
          AssetHat.config[type.to_s]['bundles'].blank?

  AssetHat.config[type.to_s]['bundles'].keys.each do |bundle|
    # Memoize commit ID for this bundle
    AssetHat.last_bundle_commit_id(bundle, type) if AssetHat.cache?

    # Memoize commit IDs for each file in this bundle
    AssetHat.bundle_filepaths(bundle, type).each do |filepath|
      AssetHat.last_commit_id(filepath)
    end
  end
end

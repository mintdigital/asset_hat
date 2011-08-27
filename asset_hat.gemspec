# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{asset_hat}
  s.version = "0.4.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Ron DeVera", "Mint Digital"]
  s.date = %q{2011-08-08}
  s.description = %q{Load CSS and JS faster. Minifies, bundles, and optimizes CSS/JS assets ahead of time (e.g., on deploy), not at runtime. Loads popular third-party JS (like jQuery, YUI, and Dojo) from localhost in development, and auto-switches to Google's CDN in production. Lets you switch on LABjs mode to load more scripts in parallel. Can rewrite stylesheets to use CDN hosts (not just your web server) and cache-busting hashes for updated images.}
  s.email = %q{hello@rondevera.com}
  s.extra_rdoc_files = [
    "LICENSE",
    "README.rdoc"
  ]
  s.files = [
    ".gemtest",
    "Gemfile",
    "HISTORY",
    "LICENSE",
    "README.rdoc",
    "Rakefile",
    "VERSION.yml",
    "asset_hat.gemspec",
    "config/assets.yml",
    "doc/classes/AssetHat.html",
    "doc/classes/AssetHat/CSS.html",
    "doc/classes/AssetHat/CSS/Engines.html",
    "doc/classes/AssetHat/JS.html",
    "doc/classes/AssetHat/JS/Engines.html",
    "doc/classes/AssetHat/JS/Vendors.html",
    "doc/classes/AssetHatHelper.html",
    "doc/created.rid",
    "doc/files/HISTORY.html",
    "doc/files/LICENSE.html",
    "doc/files/README_rdoc.html",
    "doc/files/lib/asset_hat/capistrano_rb.html",
    "doc/files/lib/asset_hat/css_rb.html",
    "doc/files/lib/asset_hat/initializers/action_view_rb.html",
    "doc/files/lib/asset_hat/initializers/cache_last_commit_ids_rb.html",
    "doc/files/lib/asset_hat/js/vendors_rb.html",
    "doc/files/lib/asset_hat/js_rb.html",
    "doc/files/lib/asset_hat/railtie_rb.html",
    "doc/files/lib/asset_hat/tasks/css_rb.html",
    "doc/files/lib/asset_hat/tasks/js_rb.html",
    "doc/files/lib/asset_hat/tasks_rb.html",
    "doc/files/lib/asset_hat/unicorn_rb.html",
    "doc/files/lib/asset_hat/vcs_rb.html",
    "doc/files/lib/asset_hat/version_rb.html",
    "doc/files/lib/asset_hat_helper_rb.html",
    "doc/files/lib/asset_hat_rb.html",
    "doc/files/lib/tasks/asset_hat_rake.html",
    "doc/fr_class_index.html",
    "doc/fr_file_index.html",
    "doc/fr_method_index.html",
    "doc/index.html",
    "doc/rdoc-style.css",
    "lib/asset_hat.rb",
    "lib/asset_hat/capistrano.rb",
    "lib/asset_hat/css.rb",
    "lib/asset_hat/initializers/action_view.rb",
    "lib/asset_hat/initializers/cache_last_commit_ids.rb",
    "lib/asset_hat/js.rb",
    "lib/asset_hat/js/vendors.rb",
    "lib/asset_hat/railtie.rb",
    "lib/asset_hat/tasks.rb",
    "lib/asset_hat/tasks/css.rb",
    "lib/asset_hat/tasks/js.rb",
    "lib/asset_hat/unicorn.rb",
    "lib/asset_hat/vcs.rb",
    "lib/asset_hat/version.rb",
    "lib/asset_hat_helper.rb",
    "lib/tasks/asset_hat.rake",
    "public/javascripts/bundles/js-bundle-1.min.js",
    "public/javascripts/bundles/js-bundle-2.min.js",
    "public/javascripts/js-file-1-1.js",
    "public/javascripts/js-file-1-2.js",
    "public/javascripts/js-file-1-3.js",
    "public/javascripts/js-file-2-1.js",
    "public/javascripts/js-file-2-2.js",
    "public/javascripts/js-file-2-3.js",
    "public/stylesheets/bundles/css-bundle-1.min.css",
    "public/stylesheets/bundles/css-bundle-2.min.css",
    "public/stylesheets/bundles/ssl/css-bundle-1.min.css",
    "public/stylesheets/bundles/ssl/css-bundle-2.min.css",
    "public/stylesheets/bundles/ssl/css-bundle-3.min.css",
    "public/stylesheets/css-file-1-1.css",
    "public/stylesheets/css-file-1-2.css",
    "public/stylesheets/css-file-1-3.css",
    "public/stylesheets/css-file-2-1.css",
    "public/stylesheets/css-file-2-2.css",
    "public/stylesheets/css-file-2-3.css",
    "rails/init.rb",
    "test/asset_hat_helper_test.rb",
    "test/asset_hat_test.rb",
    "test/test_helper.rb"
  ]
  s.homepage = %q{http://mintdigital.github.com/asset_hat}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.4.2}
  s.summary = %q{Your assets are covered.}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<flexmock>, ["~> 0.8.6"])
      s.add_development_dependency(%q<hanna>, ["~> 0.1.12"])
      s.add_development_dependency(%q<jeweler>, ["~> 1.6.0"])
      s.add_development_dependency(%q<shoulda>, ["~> 2.10.2"])
      s.add_runtime_dependency(%q<cssmin>, ["~> 1.0.2"])
      s.add_runtime_dependency(%q<jsmin>, ["~> 1.0.1"])
    else
      s.add_dependency(%q<flexmock>, ["~> 0.8.6"])
      s.add_dependency(%q<hanna>, ["~> 0.1.12"])
      s.add_dependency(%q<jeweler>, ["~> 1.6.0"])
      s.add_dependency(%q<shoulda>, ["~> 2.10.2"])
      s.add_dependency(%q<cssmin>, ["~> 1.0.2"])
      s.add_dependency(%q<jsmin>, ["~> 1.0.1"])
    end
  else
    s.add_dependency(%q<flexmock>, ["~> 0.8.6"])
    s.add_dependency(%q<hanna>, ["~> 0.1.12"])
    s.add_dependency(%q<jeweler>, ["~> 1.6.0"])
    s.add_dependency(%q<shoulda>, ["~> 2.10.2"])
    s.add_dependency(%q<cssmin>, ["~> 1.0.2"])
    s.add_dependency(%q<jsmin>, ["~> 1.0.1"])
  end
end


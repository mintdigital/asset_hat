---
layout: default
title: AssetHat by Mint Digital
---

## _Your assets are covered._ ##

With Rails' default asset caching, CSS and JS are concatenated (not even
minified) the first time that bundle is requested. Not good enough. AssetHat
can automatically:

* Easily **minify** (strip whitespace/comments) and **bundle** (combine into a
  single file) CSS and JS on deploy to reduce file sizes and HTTP requests.
* Add an image's last [Git](http://git-scm.com/) commit ID to its
  CSS URLs to **bust browser caches** (e.g.,
  <code>/images/foo.png?ab12cd34e</code>).
* Force image URLs in your CSS to use **CDN subdomains**, not just the current
  host.

After setup, you can use these in your layouts and views:

    <%= include_css :bundle => 'application' %>
      # => <link href="/stylesheets/bundles/application.min.css"
      #          media="screen,projection" rel="stylesheet" type="text/css" />

    <%= include_js :bundles => ['plugins', 'common'] %>
      # => <script src="/javascripts/bundles/plugins.min.js"
      #            type="text/javascript"></script>
      #    <script src="/javascripts/bundles/common.min.js"
      #            type="text/javascript"></script>

And this in your deploy script:

    rake asset_hat:minify

Tested with Rails 2.3.x.

## Quick Start ##

### Installation ###

    gem install asset_hat

    # Add to your Gemfile (Bundler 0.9+):
    gem 'asset_hat', '0.x.x'

    # Add to your Rakefile:
    require 'asset_hat/tasks

### Configuration ###

    # Generate example config file
    rake asset_hat:config

    # Configure your CSS/JS bundles
    vim config/assets.yml

    # Minify and bundle your CSS/JS (can be done on deploy)
    rake asset_hat:minify

If you've set up a CSS bundle called `application` and a JS bundle called
`plugins`, this creates minified bundles at
`public/stylesheets/bundles/application.min.css` and
`public/javascripts/bundles/plugins.min.js` respectively.

### Integration ###

    # In your layout, assuming you've configured these bundles:
    <%= include_css :bundle => 'application' %>
    <%= include_js  :bundle => 'plugins' %>

    # Include jQuery; uses a local copy in development, and automatically
    # switches to Google's CDN in production:
    <%= include_js :jquery %>

In development, the browser loads your separate, unminified CSS/JS files. In
production, the minified CSS/JS bundles are loaded instead.

Have an enormous app? You can integrate gradually, using AssetHat alongside
Rails' default asset caching.

## More Info ##

Check out the [README][] for a walkthrough of configuring and integrating
AssetHat, or the complete [RDoc][] for deeper details.

Having trouble or found a bug? Open an [issue][]. Attach a patch or
[fork away][].

[README]:     http://github.com/mintdigital/asset_hat#readme
[RDoc]:       /asset_hat/doc/index.html
[issue]:      http://github.com/mintdigital/asset_hat/issues
[fork away]:  http://github.com/mintdigital/asset_hat/fork

Copyright © 2010 Mint Digital Ltd.
Released under the terms of the [MIT License][].

[MIT License]: http://github.com/mintdigital/asset_hat/blob/master/LICENSE

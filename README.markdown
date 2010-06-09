AssetHat
========
Your assets are covered.

With Rails' default asset caching, CSS and JS are concatenated (not even
minified) the first time that bundle is requested. Not good enough. AssetHat
lets you automatically:

* Easily minify and bundle CSS and JS on deploy to reduce file sizes and HTTP
  requests.
* Add an image's last Git commit ID to its CSS URLs to bust browser caches
  (e.g., `/images/foo.png?abcd789`).
* Force image URLs in your CSS to use CDN subdomains, not just the current
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



Installation
------------

1. Install the gem:

        gem install asset_hat

2. Configure the gem:

    * Using [Bundler 0.9+](http://github.com/carlhuda/bundler):

        1.  Add to your app's Gemfile: `gem 'asset_hat', '0.x.x'`

        2.  Command-line: `bundle install`

    * Using Rails' `config.gem`, add to your app's `config/environment.rb`:

        `config.gem 'asset_hat', :version => '0.x.x'`

3. In your app, create `lib/tasks/asset_hat.rake` with the following contents:

        begin
          require 'asset_hat/tasks'
        rescue LoadError
          puts "Could not load AssetHat tasks: 'asset_hat' not found."
        end



Configuration
-------------

1.  Create the default config file:

        rake asset_hat:config

2.  In your app, open the new file at `config/assets.yml`, and set up your
    CSS/JS bundles according to that file's example.

3.  Minify your bundles:

        rake asset_hat:minify

    This minifies all of the CSS/JS files listed in `config/assets.yml`,
    concatenates the minified code into bundle files, and adds CDN asset hosts
    and cache-busting commit IDs to image URLs in your CSS.

    Bundles are created as new files in `public/stylesheets/bundles/` and
    `public/javascripts/bundles/`. Your original CSS/JS files remain intact.

4.  Set your deployment script to run `rake asset_hat:minify` after deploying
    your latest CSS/JS. This overwrites previously minified bundles, and
    leaves your original CSS/JS files intact.

### Advanced configuration ###

Additional settings are supported in `config/assets.yml`:

* `engine`: Indicates how CSS and JS are minified; omit this setting to use
  the defaults. By default, CSS is minified with
  [rgrove/cssmin](http://github.com/rgrove/cssmin) (a Ruby port of Lecomte's
  YUI Compressor and Schlueter's PHP cssmin), and JS is minified with
  [rgrove/jsmin](http://github.com/rgrove/jsmin) (a Ruby port of Crockford's
  JSMin).

  If the default engines cause problems by minifying too
  strongly, try switching each to `weak`. The `weak` engines are much safer,
  but don't save as many bytes.

* `vendors`: Manage JS vendor code versions and remote URLs:

        js:
          vendors:
            jquery:
              version: 1.4.1
              remote_url: http://example.com/cdn/jquery-1.4.1.min.js

  By default, if your environment sets
  `ActionController::Base.consider_all_requests_local` to `false`, and if you
  have specified the `version` for that vendor, AssetHat will automatically
  switch to URLs from
  [Google's "AJAX Libraries" CDN](http://code.google.com/apis/ajaxlibs/). If
  you supply a `remote_url` for that vendor, AssetHat will use that instead.

  Supported vendors:

    - `jquery`
    - `jquery_ui`



Usage
-----

In your layouts and views, instead of these:

    <%= stylesheet_link_tag 'reset', 'application', 'clearfix',
                            :media => 'screen,projection',
                            :cache => 'bundles/application' %>
    <%= javascript_include_tag 'plugin-1', 'plugin-2', 'plugin-3',
                               :cache => 'bundles/application' %>

**Use these:**

    <%= include_css :bundle => 'application' %>
    <%= include_js  :bundle => 'application' %>

These turn into:

    <link href="/stylesheets/bundles/application.min.css"
      media="screen,projection" rel="stylesheet" type="text/css" />
    <script src="/javascripts/bundles/application.min.js"
      type="text/javascript"></script>

If your environment has `config.action_controller.perform_caching` set to
`true` (e.g., in production), the layout/view will include minified bundle
files. Otherwise, the separate, unminified files will be included, based on
the bundle contents you define in `config/assets.yml`.

### Advanced usage ###

You can also include single files as expected:

    <%= include_css 'reset', 'application' %>
    <%= include_js  'plugin.min', 'application' %>

Or include multiple bundles at once:

    <%= include_js :bundles => %w[plugins common] %>

When including multiple bundles at once, this yields one `<link>` or
`<script>` element per bundle.

You may want to use multiple bundles to separate plugins (rarely changed) from
application code (frequently changed). If all code is in one huge bundle, then
whenever there's a change, browsers have to re-download the whole bundle. By
using multiple bundles based on change frequency, browsers cache the rarely
changed code, and only re-download the frequently changed code.

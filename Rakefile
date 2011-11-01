require 'rake/testtask'
# require 'rake/rdoctask'
require 'hanna/rdoctask'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name        = 'asset_hat'
    gemspec.summary     = 'Your assets are covered.'
    gemspec.description = %{
      Load CSS and JS faster. Minifies, bundles, and optimizes CSS/JS assets
      ahead of time (e.g., on deploy), not at runtime. Loads popular
      third-party JS (like jQuery, YUI, and Dojo) from localhost in
      development, and auto-switches to Google's CDN in production. Lets you
      switch on LABjs mode to load more scripts in parallel. Can rewrite
      stylesheets to use CDN hosts (not just your web server) and
      cache-busting hashes for updated images.
    }.strip.split.join(' ')
    gemspec.homepage    = 'http://mintdigital.github.com/asset_hat'

    gemspec.authors     = ['Ron DeVera', 'Mint Digital']
    gemspec.email       = 'hello@rondevera.com'

    gemspec.add_development_dependency  'flexmock',   '~> 0.8.6'
    gemspec.add_development_dependency  'hanna',      '~> 0.1.12'
    gemspec.add_development_dependency  'jeweler',    '~> 1.6.0'
    gemspec.add_development_dependency  'shoulda',    '~> 2.10.2'
    gemspec.add_development_dependency  'actionpack', '~> 3.0.0'
    gemspec.add_development_dependency  'test-unit',  '~> 2.0.0'
    gemspec.add_runtime_dependency      'cssmin',     '~> 1.0.2'
    gemspec.add_runtime_dependency      'jsmin',      '~> 1.0.1'
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts 'Jeweler is not available. Install it with: `gem install jeweler`'
end

Rake::TestTask.new(:test) do |t|
  t.libs << 'lib' << 'test'
  t.pattern = 'test/*_test.rb'
  t.verbose = true
end

task :default => :test

desc 'Generate documentation'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'doc'
  rdoc.title    = 'AssetHat'
  rdoc.main     = 'README.rdoc'
  rdoc.options  += %w[--line-numbers --inline-source]
  %w[README.rdoc HISTORY LICENSE lib/*].each do |path|
    rdoc.rdoc_files.include(path)
  end
end

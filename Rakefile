require 'rake/testtask'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name        = %q{asset_hat}
    gemspec.summary     = %q{Your assets are covered.}
    gemspec.description = %q{Minify, bundle, and optimize CSS/JS assets.}
    gemspec.homepage    = %q{http://github.com/mintdigital/asset_hat}

    gemspec.authors     = ['Ron DeVera', 'Mint Digital']
    gemspec.email       = %q{ronald.devera@gmail.com}

    gemspec.add_development_dependency  'shoulda',  '>= 2.10.2'
    gemspec.add_development_dependency  'flexmock', '>= 0.8.6'
    gemspec.add_runtime_dependency      'cssmin',   '>= 1.0.2'
    gemspec.add_runtime_dependency      'jsmin',    '>= 1.0.1'
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

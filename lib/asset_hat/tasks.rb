require 'asset_hat/tasks/css'
require 'asset_hat/tasks/js'

namespace :asset_hat do

  desc 'Minifies all CSS and JS bundles'
  task :minify => :environment do
    format = ENV['FORMAT']
    print 'Minifying CSS/JS...'
    puts unless format == 'dot'

    %w[css js].each do |type|
      task = Rake::Task["asset_hat:#{type}:minify"]
      task.reenable
      task.invoke(:show_intro => false, :show_outro => false)
    end
    puts unless format == 'short'
    puts 'Done.'
  end

  namespace :minify do
    %w[css js].each do |type|
      desc "Alias for asset_hat:#{type}:minify"
      task type.to_sym => "asset_hat:#{type}:minify"
    end
  end

  desc 'Prepare configuration file'
  task :config do
    require 'asset_hat'

    template_filepath = File.join(File.dirname(__FILE__), '..', '..',
      AssetHat::RELATIVE_CONFIG_FILEPATH)
    target_filepath = AssetHat::CONFIG_FILEPATH

    if File.exists?(target_filepath)
      print "Replace #{target_filepath}? (y/n) "
      response = $stdin.gets.chomp
      unless response.downcase == 'y'
        puts 'Aborted.' ; exit
      end
    end

    FileUtils.cp(template_filepath, target_filepath)
    puts "\nWrote to #{target_filepath}. Next, open this file in your editor"
    puts 'and set up your CSS/JS bundles.'
  end

end # namespace :asset_hat

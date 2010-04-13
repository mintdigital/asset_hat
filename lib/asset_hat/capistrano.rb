Capistrano::Configuration.instance(:must_exist).load do
  after 'deploy:update_code', 'deploy:asset_hat:minify'

  namespace :deploy do
    namespace :asset_hat do
      desc 'Minify all CSS/JS with Asset Hat'
      task :minify, :roles => :assets, :except => {:no_release => true} do
        rake = fetch(:rake, "rake")
        env = fetch(:environment, fetch(:rails_env, "production"))
        run "cd #{current_path} ; #{rake} RAILS_ENV=#{env} asset_hat:minify"
      end
    end
  end
end

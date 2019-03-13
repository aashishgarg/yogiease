namespace :photofy do
  desc 'Create photofy directory.'
  task :setup => :remote_environment do
    queue! %[echo "-----> making a photofy directory in shared path ---------." ]
    queue! %[mkdir -p #{deploy_to}/#{shared_path}/photofy ]
  end
end

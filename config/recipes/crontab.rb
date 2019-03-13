namespace :crontab do
  desc "Install cronjobs"
  task :install => :remote_environment do
    command %["#{erb(File.join(__dir__, 'templates', 'crontab.erb'))}" > /tmp/crontab]
    command %[crontab /tmp/crontab]
  end
end

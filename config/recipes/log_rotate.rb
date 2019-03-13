namespace :log_rotate do
  desc 'Install log_rotate template'
  task :install => :remote_environment do
    command %[ "#{erb(File.join(__dir__, 'templates', 'log_rotate.erb'))}" > /tmp/log_rotate]
    command %[sudo -A mv -f /tmp/log_rotate /etc/logrotate.d/#{application}_log_rotate.conf]
  end
end

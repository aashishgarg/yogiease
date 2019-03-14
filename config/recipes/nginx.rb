namespace :nginx do

  desc 'Install passenger with nginx module'
  task :install => :remote_environment do
    command %[sudo apt-get update]

    command %[sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 561F9B9CAC40B2F7]
    command %[sudo -A apt-get install -y apt-transport-https ca-certificates]

    # Add Passenger APT repository
    command %[sudo -A sh -c 'echo deb https://oss-binaries.phusionpassenger.com/apt/passenger #{fetch(:ubuntu_code_name)} main > /etc/apt/sources.list.d/passenger.list']
    command %[sudo -A apt-get update]
    command %[sudo -A apt-get install -y nginx-extras libnginx-mod-http-passenger]
    command %[if [ ! -f /etc/nginx/modules-enabled/50-mod-http-passenger.conf ]; then sudo -A ln -s /usr/share/nginx/modules-available/mod-http-passenger.load /etc/nginx/modules-enabled/50-mod-http-passenger.conf ; fi]
  end

  desc "Setup nginx configuration for this application"
  task :setup => :remote_environment do
    command %[sudo -A su -c "echo '#{erb(File.join(__dir__, 'templates', 'nginx_passenger.erb'))}' > /etc/nginx/sites-enabled/#{fetch(:application)}"]
    command %[sudo -A rm -f /etc/nginx/sites-enabled/default]
  end

  %w[start stop restart].each do |command|
    # command "#{command} nginx"
    task command.to_sym => :remote_environment do
      comment %[sudo service nginx #{command}]
    end
  end
end

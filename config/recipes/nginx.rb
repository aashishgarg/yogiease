namespace :nginx do

  desc 'Install passenger with nginx module'
  task :install => :remote_environment do
    command %[sudo apt-get update]

    command %[sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 561F9B9CAC40B2F7]
    command %[sudo -A apt-get install -y apt-transport-https ca-certificates]

    # Add Passenger APT repository
    command %[sudo sh -c 'echo deb https://oss-binaries.phusionpassenger.com/apt/passenger #{fetch(:ubuntu_code_name)} main > /etc/apt/sources.list.d/passenger.list']
    command %[sudo apt-get update]

    command %[sudo apt-get install -y nginx-extras passenger]
    comment %["edit /etc/nginx/nginx.conf and uncomment passenger_root and passenger_ruby. For example, you may see this:"]
    comment %[#passenger_root /some-filename/locations.ini;]
    comment %[#passenger_ruby /usr/bin/passenger_free_ruby;]
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

require 'mina/bundler'
require 'mina/rails'
require 'mina/git'
require 'mina/rvm'
require 'yaml'
require 'io/console'

%w(base nginx mysql check crontab log_rotate product_deployment_sheet).each do |pkg|
  require "#{File.join(__dir__, 'recipes', pkg)}"
end

set :application, 'yogiease'
set :user, 'deploy'
set :deploy_to, "/home/#{fetch(:user)}/#{fetch(:application)}"
set :repository, repository_url
set :branch, set_branch
set :_rvm_path, "/home/deploy/.rvm/scripts/rvm"
set :ruby_version, "#{File.readlines(File.join(__dir__, '..', '.ruby-version')).first.strip}"
set :gemset, "#{File.readlines(File.join(__dir__, '..', '.ruby-gemset')).first.strip}"
set :shared_dirs, fetch(:shared_dirs, []).push('public/system')
set :shared_files, fetch(:shared_file, []).push('config/database.yml')
set :term_mode, :nil
set :ubuntu_code_name, 'bionic' # To find out - (`lsb_release --codename | cut -f2`).
# set :sheet_name, 'Product deployment status'
# set :work_sheet_name, 'yogiease'

task :remote_environment do
  comment '<<-------------- Setting the Environment ---------------------->>'
  set :rails_env, ENV['on'].to_sym unless ENV['on'].nil?
  require "#{File.join(__dir__, 'deploy', "#{fetch(:rails_env)}_configurations_files", "#{fetch(:rails_env)}.rb")}"
  invoke :'rvm:use', "ruby-#{fetch(:ruby_version)}@#{fetch(:gemset)}"
end

task setup_prerequisites: :remote_environment do
  set :rails_env, ENV['on'].to_sym unless ENV['on'].nil?
  require "#{File.join(__dir__, 'deploy', "#{fetch(:rails_env)}_configurations_files", "#{fetch(:rails_env)}.rb")}"
  ['python-software-properties',
   'libmysqlclient-dev',
   'imagemagick',
   'libmagickwand-dev',
   'nodejs',
   'build-essential',
   'zlib1g-dev',
   'libssl-dev',
   'libreadline-dev',
   'libyaml-dev',
   'libcurl4-openssl-dev',
   'libncurses5-dev',
   'libgdbm-dev',
   'curl',
   'git-core',
   'make',
   'gcc',
   'g++',
   'pkg-config',
   'libfuse-dev',
   'libxml2-dev',
   'zip',
   'libtool',
   'memcached',
   'xvfb',
   'bison',
   'libffi-dev',
   'libpng-dev',
   'openssl',
   'mysql-client',
   # 'mysql-server',
   'mime-support',
   'automake',
   'ruby-dev',
   'nodejs-legacy'
  ].each_with_index do |package, index|
    comment "<<-----------------#{index+1} Installing (#{package}) ------------------>>"
    command %[sudo -A apt-get install -y #{package}]

  end

  comment "-----> Installing Ruby Version Manager"
  # command %[command curl -sSL https://rvm.io/mpapis.asc | gpg --import]
  # command %[curl -sSL https://get.rvm.io | bash -s stable --ruby]
  #
  # command %[source "#{fetch(:rvm_path)}"]
  # command %[rvm requirements]
  # command %[rvm install "#{fetch(:ruby_version)}"]
  command %[gem install bundler]

  command %[mkdir "#{fetch(:deploy_to)}"]
  command %[chown -R "#{fetch(:user)}" "#{fetch(:deploy_to)}"]

  invoke :'nginx:install'
  invoke :'nginx:setup'
  invoke :'nginx:restart'
end

# ================================================================================================================= #
task setup: :remote_environment do
  invoke :set_sudo_password

  command %[mkdir -p "#{fetch(:shared_path)}/log"]
  command %[chmod g+rx,u+rwx "#{fetch(:shared_path)}/log"]

  command %[mkdir -p "#{fetch(:shared_path)}/config"]
  command %[chmod g+rx,u+rwx "#{fetch(:shared_path)}/config"]

  command %[mkdir -p "#{fetch(:shared_path)}/tmp/pids"]
  command %[chmod g+rx,u+rwx "#{fetch(:shared_path)}/tmp/pids"]

  command %[touch "#{fetch(:shared_path)}/config/database.yml"]

  invoke :setup_prerequisites
  invoke :setup_yml
end

task setup_yml: :remote_environment do
  Dir[File.join(__dir__, '*.yml.example')].each do |_path|
    command %[echo "#{IO.binread(_path)}" > "#{File.join(fetch(:deploy_to), 'shared/config',
                                                         File.basename(_path, '.yml.example') +'.yml')}"]
  end
end

task set_sudo_password: :remote_environment do
  set :sudo_password, ask_sudo
  command "echo '#{IO.binread(File.join(__dir__, 'deploy', "#{fetch(:rails_env)}_configurations_files", 'sudo_password.erb'))}' > /home/#{fetch(:user)}/SudoPass.sh"
  command "chmod +x /home/#{fetch(:user)}/SudoPass.sh"
  command "export SUDO_ASKPASS=/home/#{fetch(:user)}/SudoPass.sh"
end

desc 'Restart passenger server'
task :restart => :remote_environment do
  # invoke :set_sudo_password
  invoke :'crontab:install'
  command %[sudo -A service nginx restart]
  command %[mkdir -p #{File.join(fetch(:current_path), 'tmp')}]
  command %[touch #{File.join(fetch(:current_path), 'tmp', 'restart.txt')}]
  # invoke :'product_deployment_sheet:update'
end

desc 'Deploys the current version to the server.'
task :deploy => :remote_environment do
  deploy do
    invoke :'check:revision'
    invoke :'git:clone'
    invoke :'deploy:link_shared_paths'
    invoke :'bundle:install'
    invoke :'mysql:create_database'
    invoke :'rails:db_migrate'
    invoke :'rails:assets_precompile'
  end
  on :launch do
  end
  invoke :restart
end

# ================================================================================================================= #
comment '<<-------------- Requiring all files -------------------------->>'
require 'mina/bundler'
require 'mina/rails'
require 'mina/git'
require 'mina/rvm'
require 'yaml'
require 'io/console'

%w(base nginx mysql check crontab log_rotate product_deployment_sheet).each do |pkg|
  require "#{File.join(__dir__, 'recipes', pkg)}"
end
# ================================================================================================================= #
comment '<<-------------- Setting all variables ------------------------>>'
set :application, 'quiz'
set :user, 'deploy'
set :deploy_to, "/home/#{fetch(:user)}/#{fetch(:application)}"
set :repository, repository_url
set :branch, set_branch
set :_rvm_path, "/home/deploy/.rvm/scripts/rvm"
set :ruby_version, "#{File.readlines(File.join(__dir__, '..', '.ruby-version')).first.strip}"
set :gemset, "#{File.readlines(File.join(__dir__, '..', '.ruby-gemset')).first.strip}"

# set :sheet_name, 'Product deployment status'
# set :work_sheet_name, 'quiz'

# These folders will be created in [shared] folder and referenced through symlink from current folder.
set :shared_dirs, fetch(:shared_dirs, []).push('public/system')

# These files will be created in [shared] folder and referenced through symlinking from current folder.
set :shared_files, fetch(:shared_file, []).push('config/database.yml')
set :term_mode, :nil
set :ubuntu_code_name, 'bionic' # To find out - (`lsb_release --codename | cut -f2`).

# ================================================================================================================= #
task :remote_environment do
  comment '<<-------------- Setting the Environment ---------------------->>'
  set :rails_env, ENV['on'].to_sym unless ENV['on'].nil?
  require "#{File.join(__dir__, 'deploy', "#{fetch(:rails_env)}_configurations_files", "#{fetch(:rails_env)}.rb")}"
end

# ================================================================================================================= #
task set_sudo_password: :remote_environment do
  set :sudo_password, ask_sudo
  command "echo '#{IO.binread(File.join(__dir__, 'deploy', "#{fetch(:rails_env)}_configurations_files", 'sudo_password.erb'))}' > /home/#{fetch(:user)}/SudoPass.sh"
  command "chmod +x /home/#{fetch(:user)}/SudoPass.sh"
  command "export SUDO_ASKPASS=/home/#{fetch(:user)}/SudoPass.sh"
end

# ================================================================================================================= #
desc 'Restart passenger server'
task :restart => :remote_environment do
  # invoke :set_sudo_password
  invoke :'crontab:install'
  command %[sudo -A service nginx restart]
  comment '<<---------------- Start Passenger ------------------->>'
  command %[mkdir -p #{File.join(fetch(:current_path), 'tmp')}]
  command %[touch #{File.join(fetch(:current_path), 'tmp', 'restart.txt')}]
  # invoke :'product_deployment_sheet:update'
end

# ================================================================================================================= #
task :'use:rvm', :remote_environment do |_, args|
  comment '<<*************************************************************************>>'
  comment '<<************ Ruby Version Manager not found so installing RVM  **********>>'
  comment '<<*************************************************************************>>'

  comment '<<----------- 1 ---------------------------------------------------------- >>'
  command %[gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3]
  comment '<<----------- 2 ---------------------------------------------------------- >>'
  command %[curl -sSL https://get.rvm.io | bash -s stable]
  comment '<<----------- 3 ---------------------------------------------------------- >>'
  command %[source "#{fetch(:_rvm_path)}"]
  comment '<<----------- 4 ---------------------------------------------------------- >>'
  command %[rvm autolibs disable]
  comment '<<----------- 4.1 ---------------------------------------------------------- >>'
  command %[rvm pkg install zlib]
  comment '<<----------- 5 ---------------------------------------------------------- >>'
  command %[rvm requirements]
  comment '<<----------- 6 ---------------------------------------------------------- >>'
  command %[rvm install "#{fetch(:ruby_version)}"]

  comment '<<*************************************************************************>>'
  comment '<<************ RVM Setup Done  ********************************************>>'
  comment '<<*************************************************************************>>'

  comment '<<*************************************************************************>>'
  comment '<<************ Creating New Gemset (Start) ********************************>>'
  comment '<<*************************************************************************>>'

  command %[source #{fetch(:_rvm_path)}]
  command %[rvm use #{fetch(:ruby_version)}@#{fetch(:gemset)} --create]
  command %[rvm use #{fetch(:ruby_version)}@#{fetch(:gemset)} --default]
  comment '<<*************************************************************************>>'
  comment '<<************ Creating New Gemset (End) **********************************>>'
  comment '<<*************************************************************************>>'
end

# ================================================================================================================= #
task setup_yml: :remote_environment do
  comment '<<*************************************************************************>>'
  comment '<<************** YML Setup (started) **************************************>>'
  comment '<<*************************************************************************>>'
  Dir[File.join(__dir__, '*.yml.example')].each do |_path|
    command %[echo "#{IO.binread(_path)}" > "#{File.join(fetch(:deploy_to), 'shared/config',
                                                 File.basename(_path, '.yml.example') +'.yml')}"]
  end
  comment '<<*************************************************************************>>'
  comment '<<************** YML Setup (Done) *****************************************>>'
  comment '<<*************************************************************************>>'
end

# ================================================================================================================= #
task setup_prerequisites: :remote_environment do
  comment '<<*************************************************************************>>'
  comment '<<************** Setup Prerequisites installation (Start) *****************>>'
  comment '<<*************************************************************************>>'

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
  comment '<<*************************************************************************>>'
  comment '<<************** Setup Prerequisites installation (End) *******************>>'
  comment '<<*************************************************************************>>'


  comment '<<*********** Creating Project Folder and installing BUNDLER **************>>'
  command %[mkdir "#{fetch(:deploy_to)}"]
  command %[chown -R "#{fetch(:user)}" "#{fetch(:deploy_to)}"]


  comment '<<*************************************************************************>>'
  comment '<<******************* Installing NGINX (Start)  ***************************>>'
  comment '<<*************************************************************************>>'
  invoke :'nginx:install'
  invoke :'nginx:setup'
  invoke :'nginx:restart'
  comment '<<*************************************************************************>>'
  comment '<<******************* Installing NGINX (End)  *****************************>>'
  comment '<<*************************************************************************>>'
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
  invoke :'use:rvm', "ruby-#{fetch(:ruby_version)}@#{fetch(:gemset)}"
  invoke :setup_yml

  comment '<<*************************************************************************>>'
  comment '<<************** Installing BUNDLER in Setup ******************************>>'
  comment '<<*************************************************************************>>'

  command %[gem install bundler --no-ri --no-rdoc]
  command %[sudo -A chown -R deploy /var/lib/gems]
  command %[sudo -A chown -R deploy /usr/local/bin]

  comment '<<*************************************************************************>>'
  comment '<<************** Installing BUNDLER and permissions done ******************>>'
  comment '<<*************************************************************************>>'

  command %[sudo -A reboot]
end

# ================================================================================================================= #
desc 'Deploys the current version to the server.'
task :deploy => :remote_environment do
  comment '<<*************************************************************************>>'
  comment '<<************** Deployment Started ***************************************>>'
  comment '<<*************************************************************************>>'
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
# ================================================================================================================= #
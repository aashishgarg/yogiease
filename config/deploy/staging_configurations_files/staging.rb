# Instance Details
set :host_ip, '18.223.190.162'
set :domain, fetch(:host_ip)

# Rails Environment
set :rails_env, 'production'
set :ssl_enabled, false
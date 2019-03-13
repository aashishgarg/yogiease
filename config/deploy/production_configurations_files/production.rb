# Instance Details
set :host_ip, '3.17.59.164'
set :domain, fetch(:host_ip)

# Rails Environment
set :rails_env, 'production'
set :ssl_enabled, false
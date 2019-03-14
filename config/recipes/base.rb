def repository_url
  STDOUT.puts '--- Please authenticate yourself!'
  STDOUT.print "\nEnter username for the code source repository: "
  _user_name = STDIN.gets.strip
  STDOUT.print "Enter password for user [#{_user_name}] :"
  _password = STDIN.noecho(&:gets).strip
  STDOUT.puts "\n\nThanks!"
  "https://#{_user_name}:#{_password}@github.com/aashishgarg/yogiease.git"
end

def set_branch
  default_branch = `git rev-parse --abbrev-ref HEAD`.chomp
  STDOUT.puts "\nDefault selected Branch for deployment is -> \n"
  STDOUT.puts '------------------------------------------------'
  STDOUT.puts default_branch
  STDOUT.print "\nBranch OK ?? If Yes then press [ENTER] else [enter your branch name] :"
  branch = STDIN.gets.strip
  branch = default_branch if branch.empty?
  branch
end

def ask_sudo
  STDOUT.puts '------------------------------------------------'
  STDOUT.print "\n\nEnter the password for SERVER access for user [#{fetch(:user)}]: "
  STDIN.gets.strip
end

def set_user
  default_user = 'deploy'
  STDOUT.puts "username (Default is #{default_user}) :"
  user = STDIN.gets.strip
  user = default_user if user.empty?
  user
end

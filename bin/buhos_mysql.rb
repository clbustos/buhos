require 'optparse'
require 'sequel'

options = { :host=>'localhost', :user=>'buhos', :password=>'password', :database=>'buhos_db'}

OptionParser.new do |opts|
  opts.banner = "Usage: buhos_mysql.rb [options]"

  opts.on("-hHOST", "--host=HOST", "Hostname") do |v|
    options[:host] = v
  end
  opts.on("-uUSER", "--user=USER", "User") do |v|
    options[:user] = v
  end
  opts.on("-pPASSWORD", "--password=PASSWORD", "Password") do |v|
    options[:password] = v
  end

  opts.on("-Ddatabase", "--database=DATABASE", "Database to use") do |v|
    options[:database] = v.chomp
  end
end.parse!


puts "
CREATE USER '#{options[:user]}'@'#{options[:host]}' IDENTIFIED BY '#{options[:password]}';
CREATE DATABASE #{options[:database]};
GRANT ALL PRIVILEGES ON #{options[:database]}.* TO '#{options[:user]}'@'#{options[:host]}';
"

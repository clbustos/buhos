require 'optparse'
require 'dotenv'
require 'logger'
options={}
OptionParser.new do |opts|
  opts.banner = "Usage: buhos_admin_user.rb [options]"

  opts.on("-uUSER", "--user=USER", "User to admin") do |v|
    options[:user] = v
  end
  opts.on("-pPASSWORD", "--password=PASSWORD", "Password") do |v|
    options[:password] = v
  end
end.parse!



$log=Logger.new(STDOUT)
Dotenv.load("./.env")


require_relative '../model/init.rb'
require_relative '../model/models.rb'

models=Dir.glob(File.expand_path(File.dirname(__FILE__)+"/../model/*.rb"))
Dir.glob(models).each do |f|
  require(f)
end


if !options[:user].nil? and !options[:password].nil?
	puts "Change password for user #{options[:user]}"
	user=User[:login=>options[:user]]
	if user
		user.change_password(options[:password])
		puts "Password changed succesfully"
	else
	STDERR.puts("User #{options[:user]} doesn't exists")
		exit false
	end
end

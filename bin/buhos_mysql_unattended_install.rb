require 'optparse'
require 'dotenv'
require 'sequel'
require 'logger'
require 'i18n'

options = { :host => 'localhost',
            :user => 'buhos',
            :password => 'password',
            'password_root' =>'password',
            :database => 'buhos_db',
            :port => '3306',
            :basedir => Dir.pwd,
            :language => 'en',
            :reset => false}




OptionParser.new do |opts|
  opts.banner = "Usage: buhos_unattended_installation.rb [options]"

  opts.on("-hHOST", "--host=HOST", "Hostname") do |v|
    options[:host] = v
  end
  opts.on("-uUSER", "--user=USER", "User") do |v|
    options[:user] = v
  end
  opts.on("-pPASSWORD", "--password=PASSWORD", "Password") do |v|
    options[:password] = v
  end
  opts.on("-tPASSWORDROOT","--root_password=PASSWORDROOT","Root password") do |v|
    options[:root_password]=v
  end


  opts.on("-Ddatabase", "--database=DATABASE", "Database to use") do |v|
    options[:database] = v.chomp
  end
  opts.on("-bBASEDIR", "--basedir=BASEDIR", "Path to basedir") do |v|
    options[:basedir] = v.chomp
  end
  opts.on("-rPORT", "--port=PORT", "Port to mysql") do |v|
    options[:port] = v.chomp
  end

  opts.on("-lLANGUAGE", "--language=LANGUAGE", "Language") do |v|
    options[:language] = v.chomp
  end
  opts.on("-r", "--reset", "Delete the database previous to installation") do |v|
    options[:reset] = v
  end
end.parse!


path = options[:basedir]
dir_stat = File.stat(path)

owner_uid = dir_stat.uid
group_gid = dir_stat.gid

env_file = File.join(path, ".env")

::I18n.load_path+=Dir[File.expand_path(File.join(path, 'config','locales', '*.yml'))]

::I18n.config.available_locales = [:es,:en,:pl]

::I18n.default_locale=options[:language]

if options[:reset]
  require 'mysql2'
  client = Mysql2::Client.new(:host => options[:host], :username => "root", :port => options[:port],
                              :password=>options[:root_password])
  database_escaped = client.escape(options[:database])

  client.query "DROP DATABASE IF EXISTS #{database_escaped}"
  client.query "CREATE DATABASE #{database_escaped}"
  client.close


unless File.exist?(env_file)
  require 'mysql2'
  client = Mysql2::Client.new(:host => options[:host], :username => "root", :port => options[:port], :password=>options[:root_password])
  user_escaped = client.escape(options[:user])
  host_escaped = client.escape(options[:host])

  password_escaped = client.escape(options[:password])
  database_escaped = client.escape(options[:database])

  puts client.query("DROP USER '#{user_escaped}'@'#{host_escaped}'")
  puts client.query("flush privileges")
  puts client.query("CREATE USER '#{user_escaped}'@'#{host_escaped}' IDENTIFIED BY '#{password_escaped}'")
  puts client.query("CREATE DATABASE IF NOT EXISTS #{database_escaped}")
  puts client.query("GRANT ALL PRIVILEGES ON #{database_escaped}.* TO '#{user_escaped}'@'#{host_escaped}';")
  client.close


  connection_string = sprintf("DATABASE_URL=%s://%s:%s@%s:%d/%s", "mysql2", user_escaped, password_escaped, host_escaped,
                              options[:port], database_escaped)

  final_env = connection_string + ("\n")

  File.open(env_file, "w") { |file|
    file.puts final_env
  }
  # Only the user that runs the server and the www-data to have access to .env
  File.chown(owner_uid, group_gid, env_file)
  File.chmod(0750, env_file)

  Dotenv.load(env_file)

end

Dotenv.load(env_file)
@error_conexion = false
begin
  db = Sequel.connect(ENV['DATABASE_URL'], :encoding => 'utf8', :reconnect => true)
rescue Sequel::DatabaseConnectionError => e
  @db_url = ENV['DATABASE_URL']
  @error_conexion = e
end

if @error_conexion
  puts @error_conexion
  raise "Can't connect"

end



log_dir = File.join(path, "log")

unless File.exist? log_dir
  Dir.mkdir log_dir
  File.chown(owner_uid, group_gid, log_dir)
end

log_db_install = Logger.new(File.join(log_dir, "installer_sql.log"))

db = Sequel.connect(ENV['DATABASE_URL'], :encoding => 'utf8', :reconnect => true)
db.loggers << log_db_install

load("#{path}/lib/buhos/create_schema.rb")

Buhos::SchemaCreation.create_schema(db)
Sequel.extension :migration
Sequel::Migrator.run(db, "#{path}/db/migrations")
Buhos::SchemaCreation.create_bootstrap_data(db, options[:language])

config_dir=File.join(path, "config")
installed_file = File.join(path, "config", "installed")

unless File.exist? installed_file
  Dir.mkdir config_dir unless File.exists? config_dir
  File.chown(owner_uid, group_gid, config_dir)
  File.open(installed_file, "w") { |file| file.puts "Installed on #{DateTime.now()}" }
  File.chown(owner_uid, group_gid, installed_file)
end

puts "Installation complete!"
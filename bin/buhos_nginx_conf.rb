require 'optparse'
options = { :path=>File.expand_path(File.join(__dir__, "..")),
:ruby_path=>`which ruby`}

OptionParser.new do |opts|
  opts.banner = "Usage: buhos_nginx_conf.rb [options]"

  opts.on("-pPATH", "--path=PATH", "Path where buhos is installed. Default=#{options[:path]}") do |v|
    options[:path] = File.expand_path(v)
  end
  opts.on("-dDOMAIN", "--domain=DOMAIN", "Domain Name") do |v|
    options[:domain] = v
  end
  opts.on("-rRUBY_PATH", "--ruby-path=RUBY_PATH. Default=#{options[:ruby_path]}", "Ruby path") do |v|
    options[:ruby_path] = v.chomp
  end
  
end.parse!

if options[:domain].nil?
  raise "No domain name defined"
end

if !File.directory?(options[:path])
  system("git clone https://github.com/clbustos/buhos.git \"#{options[:path]}\"")
end

text = <<-CONF
# Default BUHOS configuracion
#
server {

        server_name #{options[:domain]};
        root #{options[:path]}/public;
        passenger_base_uri /;
        passenger_document_root #{options[:path]}/public;
        passenger_ruby #{options[:ruby_path]};
        passenger_app_env development;  
        client_max_body_size 200M;
        #location / {
                # First attempt to serve request as file, then
                # as directory, then fall back to displaying a 404.
        #       try_files $uri $uri/ =404;
        #}
        passenger_enabled on;

        location ~ ^(.*|$) {
                passenger_base_uri /;   
        }
}
CONF

File.open("/etc/nginx/sites-available/#{options[:domain]}", "w") {|fp|
  fp.puts text
}

File.symlink  "/etc/nginx/sites-available/#{options[:domain]}", "/etc/nginx/sites-enabled/#{options[:domain]}"
system("service nginx restart")

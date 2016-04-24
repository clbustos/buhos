require 'daemons'
pwd=Dir.pwd
Daemons.run_proc("app.rb",{:dir_mode=>:normal,:dir=>"#{pwd}/../pids"}) do
Dir.chdir(pwd)
exec "ruby app.rb -e production -p 4568"
end

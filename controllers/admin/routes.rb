
get '/admin/all_routes' do
    return 403 unless permiso('administracion')
    lines=[]
    Dir.glob("#{dir_base}/**/*.rb").each do |v|
      File.open(v,"rb") do |fp|
        fp.each_line do |line|
          if line=~/(get|post|put)\s+['"].+?['"]/
            lines.push(line)
          end
        end
      end
    end
    "<html><body>#{lines.sort.join('<br/>')}</body></html>"

end
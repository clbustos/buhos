require 'bibtex'

if ARGV.empty?
  puts 'Usage: ruby envio.rb <excel_file>'
  exit(1)
end


bibtex_file = ARGV[0]

def procesar(current)
  total=current.join("\n")
  begin
    res=BibTeX.parse(total, :strip => false)
  rescue Exception => e
    puts total
    puts e
  end
end


string_fixed=File.read(bibtex_file)
valid=false
current=[]
string_fixed.each_line do |line|
  if line=~/@[A-Za-z]+\{.*/
    valid=true
  end
  if valid
    current.push(line)
  end
  if line.strip=="}"
    valid=false
    procesar(current)
    current=[]
  end
end
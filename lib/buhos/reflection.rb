module Buhos
  # Methods to explore the structure of the application
  module Reflection
    # Class to explore authorizations
    class Authorizations
      attr_reader :files
      attr_reader :permits
      def initialize(app)
        @app=app
        @files={}
        @permits=[]
        get_auth_from_ruby_files
        get_auth_from_haml
        @permits.flatten!.uniq!.sort!

      end
      def get_auth_from_ruby_files
        Dir.glob("#{@app.dir_base}/**/*.rb").each do |v|
          @auth=[]
          next if v=~/\/spec\// or v=~/installer.rb/
          File.open(v,"rb") do |fp|
            filename=v.gsub(@app.dir_base,"")
            @files[filename]={}
            fp.each_line do |line|
              if line=~/(get|post|put)\s+['"].+?['"]/
                current_route=line
                @files[filename][current_route]=[]
              elsif line=~/def auth|add_auth|def halt_unless/
                # Do nothing
              elsif line=~/authorization\(/ or line=~/halt_unless_auth/
                @files[filename][current_route].push(line) unless @files[filename][current_route].nil?
                scanner=line.scan(/(auth|halt_unless_auth)\((?:'|")(.+)(?:'|")\)/)
                if scanner.length>0
                  @permits.push(scanner.map {|sca| sca[1]})
                end
              end
            end
          end
        end
      end
      def get_auth_from_haml
        Dir.glob("#{@app.dir_base}/views/*.haml").each do |v|
          File.open(v,"rb") do |fp|
            filename=v.gsub(@app.dir_base,"")
            @files[filename]={:nil=>[]}
            fp.each_line do |line|
              if line=~/authorization\(/
                @files[filename][:nil].push(line) unless @files[filename][:nil].nil?
                scanner=line.scan(/(auth|halt_unless_auth)\((?:"|')(.+)(?:"|')\)/)
                if scanner.length>0
                  @permits.push(scanner.map {|sca| sca[1]})
                end
              end
            end
          end
        end
      end
    end

    def self.get_routes(app)
      lines = []
      Dir.glob("#{app.dir_base}/**/*.rb").each do |v|
        File.open(v, "rb") do |fp|
          fp.each_line do |line|
            if line =~ /(get|post|put)\s+['"].+?['"]/
              lines.push(line)
            end
          end
        end
      end
      lines
    end

    def self.get_authorizations(app)
      Authorizations.new(app)
    end


  end
end
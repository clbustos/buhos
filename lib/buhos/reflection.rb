# Copyright (c) 2016-2022, Claudio Bustos Navarrete
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# * Neither the name of the copyright holder nor the names of its
#   contributors may be used to endorse or promote products derived from
#   this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#
module Buhos
  # Methods to explore the structure of the application
  module Reflection
    # Class to explore authorizations
    class Authorizations
      attr_reader :files
      attr_reader :permits
      # @param
      def initialize(app)
        @app=app
        @files={}
        @permits=[]
        get_auth_from_ruby_files
        get_auth_from_haml
        @permits.flatten!.uniq!.sort!
        @current_route=nil
      end
      def get_auth_from_ruby_files
        Dir.glob("#{@app.dir_base}/**/*.rb").each do |v|
          @auth=[]
          next if v=~/\/spec\// or v=~/installer.rb/
          File.open(v,"rb") do |fp|
            filename=v.gsub(@app.dir_base,"")
            @files[filename]={}
            fp.each_line do |line|
              process_line_ruby_file(filename, line)
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
              process_haml_line(filename, line)
            end
          end
        end
      end

      private
      def process_haml_line(filename, line)
        if line =~ /authorization\(/
          @files[filename][:nil].push(line) unless @files[filename][:nil].nil?
          scanner = line.scan(/(auth|halt_unless_auth)\((?:"|')(.+)(?:"|')\)/)
          if scanner.length > 0
            @permits.push(scanner.map {|sca| sca[1]})
          end
        end
      end

      def process_line_ruby_file(filename, line)
        if line =~ /(get|post|put)\s+['"].+?['"]/
          @current_route = line
          @files[filename][@current_route] = []
        elsif line =~ /def auth|add_auth|def halt_unless/
          # Do nothing
        elsif line =~ /authorization\(/ or line =~ /halt_unless_auth/
          @files[filename][@current_route].push(line) unless @files[filename][@current_route].nil?
          scanner = line.scan(/(auth|halt_unless_auth)\((?:'|")(.+)(?:'|")\)/)
          if scanner.length > 0
            @permits.push(scanner.map {|sca| sca[1]})
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
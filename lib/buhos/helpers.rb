# Copyright (c) 2016-2024, Claudio Bustos Navarrete
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
  # Misc helpers for Buhos
  module Helpers



    # Provides log access
    def log
      $log
    end

    # Base dir por whole app
    def dir_base
      File.expand_path(File.dirname(__FILE__)+"/../..")
    end
    def dir_files
      dir_files= $test_mode ? "/spec/usr/files" : "/usr/files"
      dir=File.expand_path(dir_base + "/"+ dir_files)
      FileUtils.mkdir_p(dir) unless File.exist? dir
      dir
    end
    # Set title header for app
    def title(title)
      @title=title
    end
    # Is SCOPUS API key available?
    def scopus_available?
      !ENV['SCOPUS_KEY'].nil?
    end

    # Is NCBI API KEY available?
    def pubmed_available?
      !ENV['NCBI_API_KEY'].nil?
    end

    # Get title header within 80 chars
    def get_title_head
      if @title.length>80
        @title[0..80]+"..."
      else
        @title
      end

    end

   def ds_to_json(res)
     require 'json'
     content_type :json

     res.map {|v|
       {id:v[:id],
        value:v[:text],
        tokens:v[:text].split(/\s+/)
       }
     }.to_json
   end

    # Remove innecesary whitespaces
    def process_abstract_text(t)
      t.gsub("\.\n","***").gsub(/\s+/," ").gsub("***",".\n")
    end

    # Get an APP config
    def config_get(id)
      Configuration.get(id)
    end
    # Set an APP config
    def config_set(id,valor)
      Configuration.set(id,valor)
    end

    def time_sql(time)
      time.strftime("%Y-%m-%d %H:%M:%S")
    end
    # Truncate a text to given length and add truncate_string at the end
    def truncate(text, length = 30, truncate_string = "...")
      if text
        l = length - truncate_string.chars.length
        chars = text.chars
        #$log.info(chars[0..10])
        (chars.length > length ) ?
             (chars[0...l] + truncate_string.chars).join('').to_s :
             text
      end
    end
    # Force text x to be utf-8 compatible
    def protect_encoding(x)
      x.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
    end


    def percent_from_proportion(x)
      sprintf("%0.1f%%",x.to_f*100)
    end
  end
end

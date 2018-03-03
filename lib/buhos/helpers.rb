# Copyright (c) 2016-2018, Claudio Bustos Navarrete
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
    def title(title)
      @title=title
    end
    def scopus_available?
      !ENV['SCOPUS_KEY'].nil?
    end
    def get_title_head
      if @title.length>80
        @title[0..80]+"..."
      else
        @title
      end

    end





    # Entrega el valor para un id de configuración
    def config_get(id)
      Configuration.get(id)
    end
    # Define el valor para un id de configuración
    def config_set(id,valor)
      Configuration.set(id,valor)
    end
    def time_sql(time)
      time.strftime("%Y-%m-%d %H:%M:%S")
    end

  end
end
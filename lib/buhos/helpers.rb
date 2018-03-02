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

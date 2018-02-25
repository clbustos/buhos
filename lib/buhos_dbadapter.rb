module Buhos

  class DBAdapter
    def initialize
      @current=nil
    end
    def current
      @current
    end
    def use_db(db)
      @current=db
    end
    def update_model_association
      ::Revision_Sistematica.dataset=self[:revisiones_sistematicas]
      ::Canonico_Documento.dataset=self[:canonicos_documentos]
      ::Usuario.dataset=self[:usuarios]
      ::Busqueda.dataset=self[:busquedas]
      ::Permiso.dataset=@current[:permisos]
      ::Rol.dataset=self[:roles]
      ::PermisosRol.dataset=self[:permisos_roles]
    end
    def method_missing(m, *args, &block)
      #puts "#{m}: #{args}"
      @current.send(m, *args, &block)
      #puts "There's no method called #{m} here -- please try again."
    end
    def self.method_missing(m, *args, &block)
      raise "No se como manejar esto"
    end
  end
end
module Buhos

  class DBAdapter
    attr_accessor :logger
    def initialize
      @current=nil
    end
    def current
      @current
    end
    def use_db(db)
      @current=db
      db.loggers << @logger
    end
    # This is ugly. I know.
    # I just do it to allow testing
    def update_model_association
      ::Archivo.dataset=self[:archivos]
      ::Archivo_Cd.dataset=self[:archivos_cds]
      ::Archivo_Rs.dataset=self[:archivos_rs]
      ::Asignacion_Cd.dataset=self[:asignaciones_cds]
      ::Busqueda.dataset=self[:busquedas]
      ::Canonico_Documento.dataset=self[:canonicos_documentos]
      ::Crossref_Doi.dataset=self[:crossref_dois]
      ::Crossref_Query.dataset=self[:crossref_queries]
      ::Decision.dataset=self[:decisiones]
      ::Grupo.dataset=self[:grupos]
      ::Mensaje.dataset=self[:mensajes]
      ::Mensaje_Rs.dataset=self[:mensajes_rs]
      ::Mensaje_Rs_Visto.dataset=self[:mensajes_rs_vistos]
      ::Referencia.dataset=self[:referencias]
      ::Referencia_Registro.dataset=self[:referencias_registros]
      ::Resolucion.dataset=self[:resoluciones]
      ::Registro.dataset=self[:registros]
      ::Referencia_Registro.dataset=self[:referencias_registros]
      ::Tag.dataset=self[:tags]
      ::T_Clase.dataset=self[:t_clases]
      ::Tag_En_Clase.dataset=self[:tags_en_clases]
      ::Revision_Sistematica.dataset=self[:revisiones_sistematicas]
      ::Rs_Campo.dataset=self[:rs_campos]
      ::Usuario.dataset=self[:usuarios]
      ::Permiso.dataset=self[:permisos]
      ::Rol.dataset=self[:roles]
      ::Grupo.dataset=self[:grupos]
      ::Grupo_Usuario.dataset=self[:grupos_usuarios]
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
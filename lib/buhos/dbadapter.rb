module Buhos
  # Delegation pattern for Sequel::Database
  # Used on spec to change the database between tests
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
      ::Base_Bibliografica.dataset=self[:bases_bibliograficas]
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
      ::Tag_En_Cd.dataset=self[:tags_en_cds]
      ::Tag_En_Referencia_Entre_Cn.dataset=self[:tags_en_referencias_entre_cn]
      ::Revision_Sistematica.dataset=self[:revisiones_sistematicas]
      ::Rs_Campo.dataset=self[:rs_campos]
      ::Usuario.dataset=self[:usuarios]
      ::Permiso.dataset=self[:permisos]
      ::Rol.dataset=self[:roles]
      ::Scopus_Abstract.dataset=self[:scopus_abstracts]
      ::Grupo.dataset=self[:grupos]
      ::Grupo_Usuario.dataset=self[:grupos_usuarios]
      ::PermisosRol.dataset=self[:permisos_roles]


      ::Busqueda.many_to_many :registros, :class=>Registro


      ::Registro.many_to_one :canonico_documento, :class=>Canonico_Documento

      ::Referencia.many_to_many :registros
      ::Revision_Sistematica.many_to_one :grupo
      ::Grupo.many_to_many :usuarios
    end
    def method_missing(m, *args, &block)
      #puts "#{m}: #{args}"
      @current.send(m, *args, &block)
      #puts "There's no method called #{m} here -- please try again."
    end
    def self.method_missing(m, *args, &block)
      raise "Can't handle this"
    end
  end
end
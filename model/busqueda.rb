require_relative "revision_sistematica.rb"
require_relative "registro.rb"

require 'digest'

class Busqueda < Sequel::Model
  many_to_one :revision_sistematica, :class=>Revision_Sistematica
  many_to_one :base_bibliografica, :class=>Base_Bibliografica
  many_to_many :registros, :class=>Registro

  def user_name
    user_id.nil? ? I18n::t(:No_username) : Usuario[self.user_id].nombre
  end
  def registros_n
    registros.count
  end
  def referencias_n
    referencias.count
  end

  def base_bibliografica_nombre
    base_bibliografica ? base_bibliografica.nombre : nil
  end
  def referencias
    ref_ids=$db["SELECT DISTINCT(rr.referencia_id) FROM referencias_registros rr INNER JOIN busquedas_registros br ON rr.registro_id=br.registro_id WHERE br.busqueda_id=?", self[:id]].map {|v| v[:referencia_id]}
    Referencia.where(:id=>ref_ids)
  end

  def referencias_con_canonico_n(limit=nil)
    sql_limit= limit.nil? ? "" : "LIMIT #{limit.to_i}"
    $db["SELECT d.id, d.title, d.journal,d.volume, d.pages, d.author, d.year,COUNT(DISTINCT(br.registro_id)) as n_registros, COUNT(DISTINCT(r.id)) as n_referencias FROM canonicos_documentos d INNER JOIN referencias r ON d.id=r.canonico_documento_id  INNER JOIN referencias_registros rr ON r.id=rr.referencia_id INNER JOIN busquedas_registros br ON rr.registro_id=br.registro_id WHERE br.busqueda_id=? GROUP BY d.id ORDER BY n_registros DESC #{sql_limit}", self[:id] ]
  end

  def referencias_sin_canonico_n(limit=nil)
    sql_limit= limit.nil? ? "" : "LIMIT #{limit.to_i}"
    $db["SELECT r.id, r.texto, COUNT(DISTINCT(br.registro_id)) as n FROM referencias r INNER JOIN referencias_registros rr ON r.id=rr.referencia_id INNER JOIN busquedas_registros br ON rr.registro_id=br.registro_id WHERE br.busqueda_id=? AND canonico_documento_id IS NULL GROUP BY r.id ORDER BY n DESC #{sql_limit}", self[:id] ]
  end

  def referencias_sin_canonico_con_doi_n(limit=nil)
    sql_limit= limit.nil? ? "" : "LIMIT #{limit.to_i}"
    $db["SELECT r.doi, MIN(r.texto) as texto , COUNT(DISTINCT(br.registro_id)) as n FROM referencias r INNER JOIN referencias_registros rr ON r.id=rr.referencia_id INNER JOIN busquedas_registros br ON rr.registro_id=br.registro_id WHERE br.busqueda_id=? AND canonico_documento_id IS NULL AND doi IS NOT NULL GROUP BY r.doi ORDER BY n DESC #{sql_limit}", self[:id]]
  end

  def nombre
    "#{self.base_bibliografica_nombre} - #{self.fecha}"
  end


  def actualizar_registros(ref_ids)
    registros_ya_ingresados=$db["SELECT registro_id FROM busquedas_registros WHERE busqueda_id=?", self[:id]].map {|v| v[:registro_id]}
    registros_por_ingresar = ref_ids - registros_ya_ingresados
    registros_por_borrar = registros_ya_ingresados - ref_ids
    if registros_por_ingresar
      $db[:busquedas_registros].multi_insert (registros_por_ingresar.map {|v| {:registro_id => v, :busqueda_id => self[:id]}})
    end
    if registros_por_borrar
      $db[:busquedas_registros].where(:busqueda_id => self[:id], :registro_id => registros_por_borrar).delete
    end
  end
  #
  # @return

end
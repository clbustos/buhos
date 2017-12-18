require_relative "revision_sistematica.rb"
require_relative "registro.rb"

require 'digest'

class Busqueda < Sequel::Model
  many_to_one :revision_sistematica, :class=>Revision_Sistematica
  many_to_one :base_bibliografica, :class=>Base_Bibliografica
  many_to_many :registros, :class=>Registro


  def registros_n
    registros.count
  end
  def referencias_n
    referencias.count
  end

  def base_bibliografica_nombre
    base_bibliografica.nombre
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
    $db["SELECT r.doi, r.texto, COUNT(DISTINCT(br.registro_id)) as n FROM referencias r INNER JOIN referencias_registros rr ON r.id=rr.referencia_id INNER JOIN busquedas_registros br ON rr.registro_id=br.registro_id WHERE br.busqueda_id=? AND canonico_documento_id IS NULL AND doi IS NOT NULL GROUP BY r.doi ORDER BY n DESC #{sql_limit}", self[:id]]
  end

  def nombre
    "#{self.base_bibliografica_nombre} - #{self.fecha}"
  end

  def crear_hash_update(fields, registro)
    fields.inject({}) {|ac,v|
      ac[v]= registro.send(v); ac;
    }
  end

  def procesar_canonicos

    bb=Base_Bibliografica.id_a_nombre_h
    ##$log.info(bb)
    $db.transaction(:rollback=>:reraise) do
      registros.each do |registro|
        fields = [:title,:author,:year,:journal, :volume, :pages, :doi, :journal_abbr,:abstract]

        fields_update=crear_hash_update(fields,  registro)
        ##$log.info(fields)
        registro_base_id="#{bb[registro.base_bibliografica_id]}_id".to_sym
        if registro[:canonico_documento_id].nil?
          # Verifiquemos si existe doi
          if registro[:doi].to_s=~/10\./
            can_doc=Canonico_Documento[:doi=>registro[:doi]]
          end

          if can_doc.nil?
            can_doc_id=Canonico_Documento.insert(fields_update.merge({registro_base_id => registro[:uid]}))
            can_doc=Canonico_Documento[:id=>can_doc_id]
          end
          registro.update(:canonico_documento_id=>can_doc[:id])
        else
          can_doc=Canonico_Documento[registro[:canonico_documento_id]]
          # Verificamos si tenemos una nueva información que antes no estaba
          fields_new_info=fields.find_all {|v|  (can_doc[v].nil? or can_doc[v].to_s=="") and !(registro[v].nil? or registro[v].to_s=="")   }
          ##$log.info(fields.map {|v| registro[v]})
          unless fields_new_info.nil?
            fields_update_2=crear_hash_update(fields_new_info, registro)
            can_doc.update(fields_update_2)
          end

          can_doc.update(registro_base_id=>registro[:uid])
        end
      end
    end # db.transaction
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
  def procesar_archivo
    return nil if self[:archivo_cuerpo].nil?
    if self[:archivo_tipo]=="text/x-bibtex"
      integrator=ReferenceIntegrator::BibTex::Reader.parse(self[:archivo_cuerpo])
    elsif self[:archivo_tipo]=="text/csv" # Por trabajar
      #$log.info(base_bibliografica_nombre)
      integrator=ReferenceIntegrator::CSV::Reader.parse(self[:archivo_cuerpo], base_bibliografica_nombre)
    else
      raise("No integrator defined")
    end
    ##$log.info(integrator)
    #raise("PARAR")
    $db.transaction do
      bb=Base_Bibliografica.nombre_a_id_h
      ref_ids=[]
      integrator.each do |reference|
        bb_id = bb[ reference.type.to_s ]
        raise t("error.doesnt_exist_integrator", integrator: bb_id ) if bb_id.nil?
        reg_o=Registro[:uid => reference.uid, :base_bibliografica_id=> bb_id]

        if reg_o.nil?
          reg_o_id=Registro.insert(:uid => reference.uid, :base_bibliografica_id=> bb_id)
          reg_o=Registro[reg_o_id]
        end
        ref_ids.push(reg_o[:id])


        #attr_accessor :uid,:title, :abstract, :author, :journal, :year, :volume, :pages,
        #              :type, :language, :affiliation, :doi, :keywords,:keywords_plus,
        #              :references_wos, :references_scopus, :cited, :id_wos,
        #              :id_scopus,:url, :journal_abbr

        fields = [:title,:author,:year,:journal, :volume, :pages, :doi, :journal_abbr,:abstract]

        fields_update=fields.find_all {|v| reg_o[:field].nil? and reference.send(v)!=""}.inject({}) {|ac, v|
          ac[v]= reference.send(v); ac;
        }

        reg_o.update(fields_update)

        # Procesar referencias
        cited_references=reference.cited_references
        unless cited_references.nil?
          sha256 = Digest::SHA256.new
          cit_refs_ids=[]
          cited_references.each do |cr|
            dig=Digest::SHA256.hexdigest cr
            cit_refs_ids.push(dig)
            ref_o=Referencia[dig]
            unless ref_o
              Referencia.insert(:id => dig, :texto => cr)
            end
          end
          cit_refs_ids.uniq!

          reg_o.actualizar_referencias(cit_refs_ids)
        end
      end
      actualizar_registros(ref_ids)


    end
  end





end
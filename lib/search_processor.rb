# encoding: utf-8
# Search on systematic review should be processed, to obtain all necessary information
#
class SearchProcessor
  attr_reader :search
  attr_reader :result

  def initialize(search)
    @search = search
    @result = Result.new
    if process_file
      process_canonical_documents
    end
  end

  def log_error(message)
    @result.error("#{::I18n::t(message)}: ID #{@search[:id]}")
  end

  def log_success(message)
    @result.success("#{::I18n::t(message)}:ID #{@search[:id]}")
  end


  def process_file
    begin
      integrator = get_integrator
      return false if !integrator
    rescue ReferenceIntegrator::BibTex::RecordBibtexError
      log_error("search_processor.error_processing_file")
      return false
    end

    #$log.info(integrator)
    correct = true
    $db.transaction do
      bb = Base_Bibliografica.nombre_a_id_h
      ref_ids = []
      ref_i = 0
      integrator.each do |reference|

        ref_i += 1
        if reference.nil?
          @result.error(::I18n::t("search_processor.error_on_reference", i: ref_i))
          correct = false
          next
        end
        #$log.info(Encoding::default_external)
        #$log.info(reference.to_s.encoding)
        bb_id = bb[reference.type.to_s]
        #$log.info(reference.type.to_s )
        if bb_id.nil?
          @result.error(::I18n::t("search_processor.no_unique_id_for_integrator", integrator: bb_id))
          correct = false
          break
        end

        reg_o=process_reference(bb_id, reference)
        ref_ids.push(reg_o[:id])
      end
      @search.actualizar_registros(ref_ids)
    end
    log_success("search_processor.Search_process_file_successfully") if correct
    true
  end

  def process_canonical_documents

    bb = Base_Bibliografica.id_a_nombre_h
    ##$log.info(bb)
    $db.transaction(:rollback => :reraise) do

      @search.registros.each do |registro|
        fields = [:title, :author, :year, :journal, :volume, :pages, :doi, :journal_abbr, :abstract]

        fields_update = crear_hash_update(fields, registro)
        ##$log.info(fields)
        registro_base_id = "#{bb[registro.base_bibliografica_id]}_id".to_sym

        if registro[:canonico_documento_id].nil?
          # Verifiquemos si existe doi
          if registro[:doi].to_s =~ /10\./
            can_doc = Canonico_Documento[:doi => registro[:doi]]
          end

          if can_doc.nil?
            can_doc_id = Canonico_Documento.insert(fields_update.merge({registro_base_id => registro[:uid]}))
            can_doc = Canonico_Documento[:id => can_doc_id]
          end
          registro.update(:canonico_documento_id => can_doc[:id])
        else


          update_cd_fields(fields, registro, registro_base_id)

        end
      end
    end # db.transaction
    log_success("search_processor.Search_canonical_documents_successfully")
  end

  def crear_hash_update(fields, registro)
    fields.inject({}) {|ac, v|
      ac[v] = registro.send(v); ac;
    }
  end


  def get_integrator
    if @search[:archivo_cuerpo].nil?
      log_error(:No_file_available)
      false
    elsif @search[:archivo_tipo] == "text/x-bibtex" or @search[:archivo_nombre] =~ /\.bib$/
      ReferenceIntegrator::BibTex::Reader.parse(@search[:archivo_cuerpo])
    elsif @search[:archivo_tipo] == "text/csv" # Por trabajar
      #$log.info(base_bibliografica_nombre)
      ReferenceIntegrator::CSV::Reader.parse(@search[:archivo_cuerpo], @search.base_bibliografica_nombre)
    else
      log_error("search_processor.no_integrator_for_filetype")
      false
    end
  end

  def get_cit_refs_ids(cited_references)
    cit_refs_ids = []
    cited_references.each do |cr|
      dig = Digest::SHA256.hexdigest cr
      cit_refs_ids.push(dig)
      ref_o = Referencia[dig]
      unless ref_o
        Referencia.insert(:id => dig, :texto => cr)
      end
    end
    cit_refs_ids.uniq!
    cit_refs_ids
  end

  def update_cd_fields(fields, registro, registro_base_id)
    can_doc = Canonico_Documento[registro[:canonico_documento_id]]
    # Verificamos si tenemos una nueva información que antes no estaba
    raise Buhos::NoCdIdError, registro[:canonico_documento_id] if !can_doc
    fields_new_info = fields.find_all {|v| (can_doc[v].nil? or can_doc[v].to_s == "") and !(registro[v].nil? or registro[v].to_s == "")}
    ##$log.info(fields.map {|v| registro[v]})
    unless fields_new_info.nil?
      fields_update_2 = crear_hash_update(fields_new_info, registro)
      can_doc.update(fields_update_2)
    end

    can_doc.update(registro_base_id => registro[:uid])
  end


  private :get_cit_refs_ids
  private :update_cd_fields

  def process_reference(bb_id, reference)
    reg_o = Registro[:uid => reference.uid, :base_bibliografica_id => bb_id]

    if reg_o.nil?
      reg_o_id = Registro.insert(:uid => reference.uid, :base_bibliografica_id => bb_id)
      reg_o = Registro[reg_o_id]
    end


    #attr_accessor :uid,:title, :abstract, :author, :journal, :year, :volume, :pages,
    #              :type, :language, :affiliation, :doi, :keywords,:keywords_plus,
    #              :references_wos, :references_scopus, :cited, :id_wos,
    #              :id_scopus,:url, :journal_abbr

    fields = [:title, :author, :year, :journal, :volume, :pages, :doi, :journal_abbr, :abstract]

    fields_update = fields.find_all {|v| reg_o[:field].nil? and reference.send(v) != ""}.inject({}) {|ac, v|
      ac[v] = reference.send(v); ac;
    }

    reg_o.update(fields_update)

    # Procesar referencias
    cited_references = reference.cited_references
    unless cited_references.nil?
      cit_refs_ids = get_cit_refs_ids(cited_references)
      reg_o.update_references(cit_refs_ids)
    end
    reg_o
  end

end
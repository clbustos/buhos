

get '/reviews' do
  error(403) unless permiso('ver_revisiones')
  @usuario=Usuario[session['user_id']]
  @show_inactives=params['show_inactives']
  @show_inactives||='only_actives'
  @show_only_user=params['show_only_user']
  @show_only_user||='yes'
  if @show_only_user=='yes'
    @revisiones=Revision_Sistematica.get_revisiones_por_usuario(@usuario.id)
  else
    @revisiones=Revision_Sistematica
  end


  @revisiones=@revisiones.where(:activa => 1) if @show_inactives=='only_actives'


  haml :reviews
end


get '/review/new' do
  require 'date'
  title(t(:Systematic_review_new))
  first_group=Usuario[session['user_id']].grupos.first
  administrator=first_group[:administrador_grupo]
  @revision=Revision_Sistematica.new(activa:true,
                                     etapa: "search",
                                     grupo:first_group,
                                     administrador_revision:administrator,
                                     fecha_inicio: Date.today
                                     )
  @taxonomy_categories_id=[]

  haml %s{systematic_reviews/edit}
end


get "/review/:id" do |id|
  @revision=Revision_Sistematica[id]
  ##$log.info(@nombres_trs)

  @taxonomy_categories=@revision.taxonomy_categories_hash


  haml %s{systematic_reviews/view}
end

get "/review/:id/edit" do |id|
  @revision=Revision_Sistematica[id]
  @taxonomy_categories_id=@revision.taxonomy_categories_id
  title(t(:Systematic_review_edit, sr_name:@revision.nombre))
  haml %s{systematic_reviews/edit}
end



post '/review/update' do
  id=params['revision_id']
  otros_params=params
  otros_params.delete("revision_id")
  otros_params.delete("captures")
  strc=params.delete("srtc")
  #No nulos
  ##$log.info(otros_params)
  otros_params=otros_params.inject({}) {|ac,v|
    ac[v[0].to_sym]=v[1];ac
  }
  #  aa=Revision_Sistematica.new
  $log.info(otros_params)

  $db.transaction(:rollback=>:reraise) do
    if(id=="")
      id=Revision_Sistematica.insert(otros_params)
    else
      revision=Revision_Sistematica[id]
      revision.update(otros_params)
    end

    Systematic_Review_SRTC.where(:sr_id=>id).delete
    if !strc.nil? and !strc.keys.nil?
      strc.keys.each {|key|
        Systematic_Review_SRTC.insert(:sr_id=>id, :srtc_id=>key.to_i)
      }
    end
  # Procesamos los srtc
  end

  redirect url("/review/#{id}")
end


get '/review/:id/analysis' do |id|
  @revision=Revision_Sistematica[id]
  redirect to ("/review/#{@revision[:id]}/#{@revision[:etapa]}")
end


#### DOCUMENTOS CANONICOS #####

get '/review/:id/canonical_documents' do |id|

  @pager=get_pager

  @pager.orden||="n_total_referencias_recibidas__desc"

  @sin_abstract=params['sin_abstract']=='true'
  @solo_registros=params['solo_registros']=='true'
  @revision=Revision_Sistematica[id]
  @ars=AnalisisRevisionSistematica.new(@revision)
  @cd_total_ds=@revision.canonicos_documentos

  # Repetidos doi
  @cd_rep_doi=@revision.doi_repetidos
  ##$log.info(@cd_rep_doi)

  @url="/review/#{id}/canonical_documents"
  @cds_pre=@revision.canonicos_documentos.left_join(@revision.cuenta_referencias_entre_canonicos, cd_id: Sequel[:canonicos_documentos][:id]).left_join(@revision.cuenta_referencias_rtr, cd_destino: :cd_id)



  if @pager.busqueda
    @cds_pre=@cds_pre.where(Sequel.ilike(:title, "%#{@pager.busqueda}%"))
  end
  if @sin_abstract
    @cds_pre=@cds_pre.where(:abstract=>nil)
  end
  if @solo_registros
    @cds_pre=@cds_pre.where(:id=>@ars.cd_reg_id)
  end



  @cds_total=@cds_pre.count


  @pager.max_page=(@cds_total/@pager.cpp.to_f).ceil

#  $log.info(@pager)


  @criterios_orden={:n_referencias_rtr=>"Referencias RTR", :n_total_referencias_recibidas=>"Citado por", :n_total_referencias_hechas=>"Cita a",  :title=>"Título", :year=> "Año", :author=>"Autor"}


  @cds=@pager.ajustar_query(@cds_pre)

  @ars=AnalisisRevisionSistematica.new(@revision)


  haml %s{systematic_reviews/canonical_documents}
end


get '/review/:id/repeated_canonical_documents' do |id|
  @revision=Revision_Sistematica[id]
  @cd_rep_doi=@revision.doi_repetidos
  @cd_hash=@revision.canonicos_documentos.as_hash

  @cd_por_doi=Canonico_Documento.where(:doi => @cd_rep_doi).to_hash_groups(:doi, :id)
  ##$log.info(@cd_por_doi)
  haml %s{systematic_reviews/repeated_canonical_documents}
end


get '/review/:id/canonical_documents_graphml' do |id|
  @revision=Revision_Sistematica[id]

  headers["Content-Disposition"] = "attachment;filename=graphml_revision_#{id}.graphml"

  content_type 'application/graphml+xml'
  graphml=GraphML_Builder.new(@revision, nil)
  graphml.generate_graphml
end




get '/review/:id/tags' do |id|
  @revision=Revision_Sistematica[id]

  @etapas_lista={:NIL=>"--Todas--"}.merge(Revision_Sistematica::ETAPAS_NOMBRE)

  @select_etapa=get_xeditable_select(@etapas_lista, "/tags/classes/edit_field/etapa","select_etapa")
  @select_etapa.nil_value=:NIL
  @tipos_lista={general:"General", documento:"Documento", relacion:"Relación"}

  @select_tipo=get_xeditable_select(@tipos_lista, "/tags/classes/edit_field/tipo","select_tipo")

  @tag_estadisticas=@revision.tags_estadisticas


  haml %s{systematic_reviews/tags}
end


get '/review/:id/messages' do |id|
  @revision=Revision_Sistematica[id]
  @mensajes_rs=@revision.mensajes_rs_dataset.where(:respuesta_a=>nil).order(Sequel.desc(:tiempo))
  #@mensajes_rs_vistos=Mensaje_Rs_Visto.where(:visto=>true,:m_rs_id=>@mensajes_rs.select_map(:id), :usuario_id=>session['user_id']).select_map(:m_rs_id)
  #$log.info(@mensajes_rs_vistos)
  @usuario=Usuario[session['user_id']]
  haml %s{systematic_reviews/messages}
end

post '/review/:id/message/new' do |id|
  @revision=Revision_Sistematica[id]
  @usuario_id=params['user_id']
  return 404 if @revision.nil? or @usuario_id.nil?
  @asunto=params['asunto']
  @texto=params['texto']
  $db.transaction(:rollback=>:reraise) do
    id=Mensaje_Rs.insert(:revision_sistematica_id=>id, :usuario_desde=>@usuario_id, :respuesta_a=>nil, :tiempo=>DateTime.now(), :asunto=>@asunto, :texto=>@texto)
    agregar_mensaje(t("messages.new_message_for_sr", sr_name:@revision[:nombre]))
  end
  redirect back
end

get '/review/:id/files' do |id|
  @revision=Revision_Sistematica[id]
  @archivos_rs=Archivo.join(:archivos_rs, :archivo_id => :id).left_join(:archivos_cds, :archivo_id => :archivo_id).where(:revision_sistematica_id => id).order_by(:archivo_nombre)
  @modal_archivos=get_modalarchivos

  @canonicos_documentos_h=@revision.canonicos_documentos.order(:title).as_hash
  @cd_validos_id=@revision.cd_id_por_etapa(@revision.etapa)
  @cd_validos=@canonicos_documentos_h.find_all {|v| @cd_validos_id.include? v[0]}.map{|v| v[1]}
  @usuario=Usuario[session['user_id']]
  haml %s{systematic_reviews/files}
end

post '/review/files/add' do
  #$log.info(params)
  @revision=Revision_Sistematica[params['revision_sistematica_id']]
  return 404 if @revision.nil?
  archivos=params['archivos']
  cd=nil
  cd_id=params['canonico_documento_id']
  if cd_id
    cd=Canonico_Documento[cd_id]
    return 404 if cd.nil?
  end

  if archivos
    resultados=Result.new
    archivos.each do |archivo|
      resultados.add_result(Archivo.agregar_en_rs(archivo,@revision,dir_archivos,cd))
    end
    agregar_resultado resultados
  else
    agregar_mensaje(I18n::t(:Files_not_uploaded), :error)
  end
  redirect back
end


get '/review/:id/advance_stage' do |id|
  @revision=Revision_Sistematica[id]
  return 404 if @revision.nil?

  @ars=AnalisisRevisionSistematica.new(@revision)
  if (@ars.stage_complete?(@revision.etapa))
    etapa_i=Revision_Sistematica::ETAPAS.index(@revision[:etapa].to_sym)
    #$log.info(etapa_i)
    return 405 if etapa_i.nil?
    @revision.update(:etapa=>Revision_Sistematica::ETAPAS[etapa_i+1])
    agregar_mensaje(I18n::t(:stage_complete))
    redirect("/review/#{@revision[:id]}/administration/#{@revision[:etapa]}")
  else
    agregar_mensaje(I18n::t(:stage_not_yet_complete), :error)
    redirect back
  end
end
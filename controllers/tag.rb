post '/tags/classes/new' do
  halt_unless_auth('tag_edit')
  @revision=Revision_Sistematica[params['revision_id']]
  etapa=  params['etapa']
  etapa=nil if etapa=="NIL"
  tipo =  params['tipo']
  return 404 if @revision.nil?

  $db.transaction(:rollback=>:reraise) do
    T_Clase.insert(:nombre=>params["nombre"],
                   :revision_sistematica_id=>@revision.id,
                   :etapa=>etapa,
                   :tipo=>tipo)
  end
  redirect back
end


put '/tags/classes/edit_field/:campo' do |campo|
  halt_unless_auth('tag_edit')

  pk = params['pk']
  value = params['value']
  value = nil if value=="NIL"
  return 405 unless %w{nombre etapa tipo}.include? campo
  T_Clase[pk].update(campo.to_sym=>value)
  return 200
end


put "/tag/edit" do
  halt_unless_auth('tag_edit')

  pk = params['pk']
  value = params['value'].chomp
  return [405,"Debe ingresar algun texto"] if value==""
  Tag[pk].update(:texto=>value)
  return 200
end

post '/tags/class/:t_clase_id/add_tag' do |t_clase_id|
  halt_unless_auth('tag_edit')

  t_clase=T_Clase[t_clase_id]
  raise  NoTagClassIdError, t_clase_id if !t_clase
  tag_nombre=params['value'].chomp
  return 405 if tag_nombre==""
  tag=Tag.get_tag(tag_nombre)
  t_clase.asignar_tag(tag)
  partial("tags/tags_class", :locals=>{t_clase: t_clase})
end


get '/tag/:tag_id/rs/:rs_id/stage/:stage/cds' do |tag_id, rs_id, stage|
  halt_unless_auth('review_view')

  @tag=Tag[tag_id]
  raise Buhos::NoTagIdError, tag_id if !@tag
  @revision=Revision_Sistematica[rs_id]

  @ars=AnalysisSystematicReview.new(@revision)

  @usuario=Usuario[session['user_id']]
  return 404 if @tag.nil? or @revision.nil?
  @stage=stage
  @cds_tag=Tag_En_Cd.cds_rs_tag(@revision,@tag,false,stage)
  @cds=Canonico_Documento.where(:id=>@cds_tag.map(:id))
  haml '/tags/rs_cds'.to_sym
end


get '/tag/:tag_id/rs/:rs_id/cds' do |tag_id, rs_id|
  halt_unless_auth('review_view')
  @tag=Tag[tag_id]
  raise Buhos::NoTagIdError, tag_id if !@tag

  @revision=Revision_Sistematica[rs_id]

  @ars=AnalysisSystematicReview.new(@revision)

  @usuario=Usuario[session['user_id']]
  return 404 if @tag.nil? or @revision.nil?

  @cds_tag=Tag_En_Cd.cds_rs_tag(@revision,@tag)
  @cds=Canonico_Documento.where(:id=>@cds_tag.map(:id))
  haml '/tags/rs_cds'.to_sym
end






post '/tags/cd/:cd_id/rs/:rs_id/:accion' do |cd_id,rs_id,accion|
  halt_unless_auth('review_analyze')
  cd=Canonico_Documento[cd_id]
  rs=Revision_Sistematica[rs_id]
  return 405 if cd.nil? or rs.nil?

  usuario_id=session['user_id']
  if accion=='add_tag'
    tag_nombre=params['value'].chomp
    return 405 if tag_nombre==""
    tag=Tag.get_tag(tag_nombre)
    $db.transaction(:rollback=>:reraise) do
      Tag_En_Cd.aprobar_tag(cd,rs,tag,usuario_id)
    end
  elsif accion=='approve_tag'
    tag_id=params['tag_id']
    tag=Tag[tag_id]
    return 404 if tag.nil?
    $db.transaction(:rollback=>:reraise) do
      Tag_En_Cd.aprobar_tag(cd,rs,tag,usuario_id)
    end
  elsif accion=='reject_tag'
    tag_id=params['tag_id']
    tag=Tag[tag_id]
    return 404 if tag.nil?
    $db.transaction(:rollback=>:reraise) do
      Tag_En_Cd.rechazar_tag(cd,rs,tag,usuario_id)
    end
  else
    return [405,"I don't know the action to perform"]
  end

  partial("tags/tags_cd_rs", :locals=>{cd:cd, revision:rs, :nuevo=>true, usuario_id: usuario_id})
end



post '/tags/cd_start/:cd_start_id/cd_end/:cd_end_id/rs/:rs_id/:accion' do |cd_start_id,cd_end_id,rs_id,accion|
  halt_unless_auth('review_analyze')
  cd_start=Canonico_Documento[cd_start_id]
  cd_end=Canonico_Documento[cd_end_id]
  rs=Revision_Sistematica[rs_id]
  return 405 if cd_start.nil? or cd_end.nil? or rs.nil?

  usuario_id = session['user_id']

  if accion=='add_tag'
    tag_nombre=params['value'].chomp
    return 405 if tag_nombre==""
    tag=Tag.get_tag(tag_nombre)
    $db.transaction(:rollback=>:reraise) do
      Tag_En_Referencia_Entre_Cn.aprobar_tag(cd_start,cd_end,rs,tag,usuario_id)
    end
  elsif accion=='approve_tag'
    tag_id=params['tag_id']
    tag=Tag[tag_id]
    return 404 if tag.nil?
    $db.transaction(:rollback=>:reraise) do
      Tag_En_Referencia_Entre_Cn.aprobar_tag(cd_start,cd_end,rs,tag,usuario_id)
    end
  elsif accion=='reject_tag'
    tag_id=params['tag_id']
    tag=Tag[tag_id]
    return 404 if tag.nil?
    $db.transaction(:rollback=>:reraise) do
      Tag_En_Referencia_Entre_Cn.rechazar_tag(cd_start,cd_end,rs,tag,usuario_id)
    end
  else
    return [405,"I don't know the action to perform"]
  end

  partial("tags/tags_cd_rs_ref", :locals=>{cd_start: cd_start, cd_end:cd_end, revision:rs, :nuevo=>true, usuario_id: usuario_id})
end



get '/tags/basic_10.json' do
  halt_unless_auth('review_view')
  require 'json'
  content_type :json
  Tag.order(:texto).limit(10).map {|v|
    {id:v[:id],
     value:v[:texto],
     tokens:v[:texto].split(/\s+/)
    }
  }.to_json
end


get '/tags/basic_ref_10.json' do
  halt_unless_auth('review_view')
  require 'json'
  content_type :json
  Tag.order(:texto).limit(10).map {|v|
    {id:v[:id],
     value:v[:texto],
     tokens:v[:texto].split(/\s+/)
    }
  }.to_json
end

get '/tags/query_json/:query' do |query|
  halt_unless_auth('review_view')
  require 'json'
  content_type :json

  res=$db["SELECT id, texto,COUNT(*) as n from tags t INNER JOIN tags_en_cds tec ON t.id=tec.tag_id WHERE INSTR(texto,?)>0 and decision='yes' GROUP BY t.texto ORDER BY n DESC LIMIT 10", query]
  res.map {|v|
    {id:v[:id],
     value:v[:texto],
     tokens:v[:texto].split(/\s+/)
    }
  }.to_json
end


get '/tags/refs/query_json/:query' do |query|
  halt_unless_auth('review_view')
  require 'json'
  content_type :json

  res=$db["SELECT id, texto,COUNT(*) as n from tags t INNER JOIN tags_en_referencias_entre_cn tec ON t.id=tec.tag_id WHERE INSTR(texto,?)>0 and decision='yes' GROUP BY t.texto ORDER BY n DESC LIMIT 10", query]
  res.map {|v|
    {id:v[:id],
     value:v[:texto],
     tokens:v[:texto].split(/\s+/)
    }
  }.to_json
end



get '/tags/systematic_review/:rs_id/query_json/:query' do |rs_id,query|
  halt_unless_auth('review_view')
  require 'json'
  content_type :json
  
  res=$db["SELECT id, texto,COUNT(*) as n from tags t INNER JOIN tags_en_cds tec ON t.id=tec.tag_id WHERE INSTR(texto,?)>0 and decision='yes' and revision_sistematica_id=? GROUP BY t.texto ORDER BY n DESC LIMIT 10", query, rs_id ]
  res.map {|v|
    {id:v[:id],
     value:v[:texto],
     tokens:v[:texto].split(/\s+/)
    }
  }.to_json
end

get '/tags/systematic_review/:rs_id/ref/query_json/:query' do |rs_id,query|
  halt_unless_auth('review_view')
  require 'json'
  content_type :json

  res=$db["SELECT id, texto,COUNT(*) as n from tags t INNER JOIN tags_en_referencias_entre_cn tec ON t.id=tec.tag_id WHERE INSTR(texto,?)>0 and decision='yes' and revision_sistematica_id=? GROUP BY t.texto ORDER BY n DESC LIMIT 10", query, rs_id ]
  res.map {|v|
    {id:v[:id],
     value:v[:texto],
     tokens:v[:texto].split(/\s+/)
    }
  }.to_json
end



post '/tag/delete_rs' do
  halt_unless_auth('tag_edit')
  rs=Revision_Sistematica[params['rs_id']]
  tag=Tag[params['tag_id']]
  return 404 if rs.nil? or tag.nil?
  $db.transaction(:rollback=>:reraise) {
    Tag_En_Cd.where(:tag_id=>tag.id, :revision_sistematica_id=>rs.id).delete
    if Tag_En_Cd.where(:tag_id=>tag.id).empty? and Tag_En_Referencia_Entre_Cn.where(:tag_id=>tag.id).empty?
      Tag[tag.id].delete
    end
  }
  return 200
end


# Not supported code
#
# get '/tag/:tag_id/review/:rs_id/assign_user/:usuario_id' do |tag_id,rs_id,user_id|
#   tag=Tag[tag_id]
#   revision=Revision_Sistematica[rs_id]
#   usuario=Usuario[user_id]
#   tec_cd_id=Tag_En_Cd.cds_rs_tag( revision,tag,true,revision.etapa).select_map(:id)
#   a_cd=Asignacion_Cd.where(:revision_sistematica_id=>rs_id,:usuario_id=>user_id, :canonico_documento_id=>tec_cd_id).select_map(:canonico_documento_id)
#   por_agregar=tec_cd_id-a_cd
#     if por_agregar.length>0
#       $db.transaction(:rollback=>:reraise) do
#         por_agregar.each do |cd_id|
#         Asignacion_Cd.insert(:revision_sistematica_id=>rs_id,:usuario_id=>user_id, :canonico_documento_id=>cd_id, :estado=>'assigned')
#         end
#       end
#       agregar_mensaje("Agregados cd #{por_agregar.join(',')}  a usuario #{user_id} en revision sistematica #{revision.nombre}")
#     end
#
#   redirect back
# end
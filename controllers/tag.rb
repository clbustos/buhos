post '/tags/clases/nueva' do
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


put '/tags/clases/editar_campo/:campo' do |campo|
  pk = params['pk']
  value = params['value']
  value = nil if value=="NIL"
  return 405 unless %w{nombre etapa tipo}.include? campo
  T_Clase[pk].update(campo.to_sym=>value)
  return 200
end


put "/tag/editar" do
  pk = params['pk']
  value = params['value'].chomp
  return [404,"Debe ingresar algun texto"] if value==""
  Tag[pk].update(:texto=>value)
  return 200
end

post '/tags/clase/:t_clase_id/agregar_tag' do |t_clase_id|
  t_clase=T_Clase[t_clase_id]
  return 404 if t_clase.nil?
  tag_nombre=params['value'].chomp
  return 405 if tag_nombre==""
  tag=Tag.get_tag(tag_nombre)
  t_clase.asignar_tag(tag)
  partial("tags/tags_clase", :locals=>{t_clase: t_clase})
end


get '/tag/:tag_id/rs/:rs_id/cds' do |tag_id, rs_id|
  @tag=Tag[tag_id]
  @revision=Revision_Sistematica[rs_id]

  @ars=AnalisisRevisionSistematica.new(@revision)

  @usuario=Usuario[session['user_id']]
  return 404 if @tag.nil? or @revision.nil?
  @cds_tag=Tag_En_Cd.cds_rs_tag(@revision,@tag)
  haml '/tags/rs_cds'.to_sym
end

post '/tags/cd/:cd_id/rs/:rs_id/:accion' do |cd_id,rs_id,accion|
  cd=Canonico_Documento[cd_id]
  rs=Revision_Sistematica[rs_id]
  return 405 if cd.nil? or rs.nil?

  usuario_id=session['user_id']
  if accion=='agregar_tag'
    tag_nombre=params['value'].chomp
    return 405 if tag_nombre==""
    tag=Tag.get_tag(tag_nombre)
  $db.transaction(:rollback=>:reraise) do
    Tag_En_Cd.aprobar_tag(cd,rs,tag,usuario_id)
  end
  elsif accion=='aprobar_tag'
    tag_id=params['tag_id']
    tag=Tag[tag_id]
    return 404 if tag.nil?
    $db.transaction(:rollback=>:reraise) do
      Tag_En_Cd.aprobar_tag(cd,rs,tag,usuario_id)
    end
  elsif accion=='rechazar_tag'
    tag_id=params['tag_id']
    tag=Tag[tag_id]
    return 404 if tag.nil?
    $db.transaction(:rollback=>:reraise) do
      Tag_En_Cd.rechazar_tag(cd,rs,tag,usuario_id)
    end
  else
    [405,"No se cual es la accion"]
  end

  partial("tags/tags_cd_rs", :locals=>{cd:cd, revision:rs, :nuevo=>true, usuario_id: usuario_id})
end



get '/tags/basico_10.json' do
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


get '/tags/revision_sistematica/:rs_id/query_json/:query' do |rs_id,query|
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

post '/tag/borrar_rs'do
  rs=Revision_Sistematica[params['rs_id']]
  tag=Tag[params['tag_id']]
  return 404 if rs.nil? or tag.nil?
  $db.transaction(:rollback=>:reraise) {
    Tag_En_Cd.where(:tag_id=>tag.id, :revision_sistematica_id=>rs.id).delete
    if Tag_En_Cd.where(:tag_id=>tag.id).empty?
      Tag[tag.id].delete
    end
  }
  return 200
end

get '/tag/:tag_id/revision/:rs_id/asignar_usuario/:usuario_id' do |tag_id,rs_id,user_id|
  tag=Tag[tag_id]
  revision=Revision_Sistematica[rs_id]
  usuario=Usuario[user_id]
  tec_cd_id=Tag_En_Cd.cds_rs_tag( revision,tag,true,revision.etapa).select_map(:id)
  a_cd=Asignacion_Cd.where(:revision_sistematica_id=>rs_id,:usuario_id=>user_id, :canonico_documento_id=>tec_cd_id).select_map(:canonico_documento_id)
  por_agregar=tec_cd_id-a_cd
    if por_agregar.length>0
      $db.transaction(:rollback=>:reraise) do
        por_agregar.each do |cd_id|
        Asignacion_Cd.insert(:revision_sistematica_id=>rs_id,:usuario_id=>user_id, :canonico_documento_id=>cd_id, :estado=>'assigned')
        end
      end
      agregar_mensaje("Agregados cd #{por_agregar.join(',')}  a usuario #{user_id} en revision sistematica #{revision.nombre}")
    end

  redirect back
end
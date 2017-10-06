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


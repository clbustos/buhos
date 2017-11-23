get '/revision/:rs_id/campos' do |rs_id|
  @revision=Revision_Sistematica[rs_id]
  @campos=@revision.campos
  haml %s{revisiones_sistematicas/campos}
end

post '/revision/:rs_id/nuevo_campo' do |rs_id|
  @revision=Revision_Sistematica[rs_id]
  return 404 unless @revision

  nombre=params['nombre'].chomp

  @campo_previo=@revision.campos.where(:nombre=>nombre)
  if @campo_previo.empty?
    Rs_Campo.insert(:revision_sistematica_id=>rs_id, :orden=>params['orden'],:nombre=>nombre, :descripcion=>params['descripcion'], :tipo=>params['tipo'].chomp,:opciones=>params['opciones'])
    agregar_mensaje("Agregado campo #{params[:nombre]}")

  else
    agregar_mensaje("Ya existe campo con nombre #{params[:nombre]}",:error)
  end
  redirect back
end

put '/revision/editar_campo/:campo_id/:campo' do |campo_id,campo|

  return [500, "No existe campo #{campo}"] unless %w{orden nombre descripcion tipo opciones}.include? campo
  pk = params['pk']
  value = params['value']
  campo_o=Rs_Campo[pk]
  return ["No existe campo #{campo_id}"] unless campo
  campo_o.update({campo.to_sym=>value})
  return 200
end


get '/revision/:rs_id/actualizar_tabla' do |rs_id|
  @revision=Revision_Sistematica[rs_id]
  return 404 if !@revision
  @campos=@revision.campos
  Rs_Campo.actualizar_tabla(@revision)
  agregar_mensaje("Actualizada tabla")
  redirect back
end
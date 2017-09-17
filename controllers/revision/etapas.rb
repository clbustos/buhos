get '/revision/:id/revision_titulo_resumen' do |id|

  @usuario=Usuario[session['user_id']]
  @usuario_id=@usuario[:id]
  @pagina=params['pagina'].to_i
  @pagina=1 if @pagina<1
  @cpp=params['cpp']
  @cpp||=20
  @busqueda=params['busqueda']

  # $log.info(params)
  @revision=Revision_Sistematica[id]
  @ars=AnalisisRevisionSistematica.new(@revision)
  @cd_total_ds=@revision.canonicos_documentos


  @url="/revision/#{id}/revision_titulo_resumen"
  @cds_pre=@revision.canonicos_documentos(:registro)

  @ads=AnalisisDecisionUsuario.new(id,@usuario_id, 'revision_titulo_resumen')

  @cds_pre=@ads.canonicos_documentos

  @decisiones=@ads.decisiones
  if @busqueda

    cd_ids=@ads.decision_por_cd.find_all {|v|
      @busqueda==v[1]
    }.map {|v| v[0]}
    ##$log.info(cd_ids)
    @cds_pre=@cds_pre.where(:id => cd_ids)
  end


  @cds_total=@cds_pre.count

  @max_page=(@cds_total/@cpp.to_f).ceil
  @pagina=1 if @pagina>@max_page


  @cds=@cds_pre.offset((@pagina-1)*@cpp).limit(@cpp).order(:author, :year)


  haml %s{revisiones_sistematicas/revision_titulo_resumen}


end

get '/revision/:id/administracion_etapas' do |id|
  @revision=Revision_Sistematica[id]
  @ars=AnalisisRevisionSistematica.new(@revision)
  haml %s{revisiones_sistematicas/administracion_etapas}

end

get '/revision/:id/administracion/:etapa' do |id,etapa|
  @revision=Revision_Sistematica[id]
  @etapa=etapa
  @ars=AnalisisRevisionSistematica.new(@revision)
  @usuario_id=session['user_id']
  haml "revisiones_sistematicas/administracion_#{etapa}".to_sym
end


get '/revision/:id/etapa/:etapa/patron/:patron/resolucion/:resolucion' do |id,etapa,patron_s,resolucion|
  @revision=Revision_Sistematica[id]
  @ars=AnalisisRevisionSistematica.new(@revision)
  patron=@ars.patron_desde_s(patron_s)
  cds=@ars.cd_desde_patron(etapa,patron)
  $db.transaction(:rollback=>:reraise) do
    cds.each do |cd_id|
      res=Resolucion.where(:revision_sistematica_id=>id, :canonico_documento_id=>cd_id, :etapa=>etapa)
      if res.empty?
        Resolucion.insert(:revision_sistematica_id=>id, :canonico_documento_id=>cd_id, :etapa=>etapa, :resolucion=>resolucion, :usuario_id=>session['user_id'], :comentario=>"Resuelto en forma masiva en #{DateTime.now.to_s}")
      else
        res.update(:resolucion=>resolucion, :usuario_id=>session['user_id'], :comentario=>"Actualizado en forma masiva en #{DateTime.now.to_s}")

      end
    end
  end
  agregar_mensaje("Resolución #{resolucion} para #{cds.length} documentos")
  redirect back
end

post '/resolucion/revision/:id/canonico_documento/:cd_id/etapa/:etapa/resolucion' do |rev_id, cd_id, etapa|

  resolucion=params['resolucion']
  user_id=params['user_id']


  $db.transaction(:rollback=>:reraise) do

    res=Resolucion.where(:revision_sistematica_id=>rev_id, :canonico_documento_id=>cd_id, :etapa=>etapa)
    if res.empty?
      Resolucion.insert(:revision_sistematica_id=>rev_id, :canonico_documento_id=>cd_id, :etapa=>etapa, :resolucion=>resolucion, :usuario_id=>user_id, :comentario=>"Resuelto en forma especifica en #{DateTime.now.to_s}")
    else
      res.update(:resolucion=>resolucion, :usuario_id=>user_id, :comentario=>"Actualizado en forma especifica en #{DateTime.now.to_s}")
    end
  end

  revision=Revision_Sistematica[rev_id]
  ars=AnalisisRevisionSistematica.new(revision)

  res=Resolucion.where(:revision_sistematica_id=>rev_id, :canonico_documento_id=>cd_id, :etapa=>etapa)


  rpc=ars.resolucion_por_cd_calculo (etapa)

  partial(:botones_resolucion, :locals=>{:rpc=>rpc, :cd_id=>cd_id.to_i, :etapa=>etapa, :usuario_id=>user_id, :revision=>revision})
end



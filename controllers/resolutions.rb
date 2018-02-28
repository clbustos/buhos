
post '/resolution/review/:id/canonical_document/:cd_id/stage/:etapa/resolution' do |rev_id, cd_id, etapa|

  resolucion=params['resolucion']
  user_id=params['user_id']

  return 500 unless ['yes','no'].include? resolucion
  $db.transaction(:rollback=>:reraise) do

    res=Resolucion.where(:revision_sistematica_id=>rev_id, :canonico_documento_id=>cd_id, :etapa=>etapa)
    if res.empty?
      Resolucion.insert(:revision_sistematica_id=>rev_id, :canonico_documento_id=>cd_id, :etapa=>etapa, :resolucion=>resolucion, :usuario_id=>user_id, :comentario=>"Resuelto en forma especifica en #{DateTime.now.to_s}")
    else
      res.update(:resolucion=>resolucion, :usuario_id=>user_id, :comentario=>"Actualizado en forma especifica en #{DateTime.now.to_s}")
    end
  end

  revision=Revision_Sistematica[rev_id]
  ars=AnalysisSystematicReview.new(revision)

  rpc=ars.resolution_by_cd (etapa)

  partial(:buttons_resolution, :locals=>{:rpc=>rpc, :cd_id=>cd_id.to_i, :etapa=>etapa, :usuario_id=>user_id, :revision=>revision})
end
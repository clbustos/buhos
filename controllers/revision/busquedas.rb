get '/revision/:id/busquedas' do |id|
  error(403) unless permiso('busquedas_revision_ver')
  @revision=Revision_Sistematica[id]
  @busquedas=@revision.busquedas
  @header=t_systematic_review_title(@revision[:nombre], :systematic_review_searchs)
  @user=Usuario[session['user_id']]

  @url_back="/revision/#{id}/busquedas"
  haml "revisiones_sistematicas/busquedas".to_sym
end

get '/revision/:id/busquedas/user/:user_id' do |id,user_id|
  error(403) unless permiso('busquedas_revision_ver')
  @revision=Revision_Sistematica[id]

  @header=t_systematic_review_title(@revision[:nombre], t(:searchs_user, :user_name=>Usuario[user_id][:nombre]), false)
  @url_back="/revision/#{id}/busquedas/user/#{user_id}"
  @busquedas=@revision.busquedas_dataset.where(:user_id=>user_id)
  haml "revisiones_sistematicas/busquedas".to_sym
end





get '/revision/:id/busqueda/nuevo' do |id|
  error(403) unless permiso('busquedas_revision_crear')
  require 'date'

  @revision=Revision_Sistematica[id]
  @header=t_systematic_review_title(@revision[:nombre], :New_search)
  @bb_general_id=Base_Bibliografica[:nombre=>'generic'][:id]
  @busqueda=Busqueda.new(:user_id=>session['user_id'], :source=>"database_search",:valid=>false, :fecha=>Date.today, :base_bibliografica_id=>@bb_general_id)
  @usuario=Usuario[session['user_id']]
  haml "busquedas/busqueda_edicion".to_sym
end





get '/revision/:rs_id/busquedas/comparar_registros' do |rs_id|
  @revision=Revision_Sistematica[rs_id]
  return 404 if !@revision
  @cds={}
  @errores=[]
  @busquedas_id=@revision.busquedas_dataset.map(:id)
  n_busquedas=@busquedas_id.length
  @revision.busquedas.each do |busqueda|
    busqueda.registros.each do |registro|
      rcd_id=registro[:canonico_documento_id]

      if rcd_id
        @cds[rcd_id]||={:busquedas=>{}}
        @cds[rcd_id][:busquedas][busqueda[:id]]=true
      else
        errores.push(registro[:id])
      end
    end
  end
  @cds_o=Canonico_Documento.where(:id=>@cds.keys).to_hash(:id)
  @cds_ordenados=@cds.sort_by {|key,a|
    #$log.info(@busquedas_id)
    #$log.info(a)
    base_n=1+a[:busquedas].length*(2**(n_busquedas+1))
    #$log.info("Base:#{base_n}")
    sec_n=(0...n_busquedas).inject(0) {|total,aa|  total+=(a[:busquedas][@busquedas_id[aa]].nil? ) ? 0 : 2**aa;total}
    #$log.info("Sec:#{sec_n}")
    base_n+sec_n
  }

  haml "busquedas/busquedas_comparar_registros".to_sym
end
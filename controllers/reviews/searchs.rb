get '/review/:id/searchs' do |id|
  error(403) unless permiso('busquedas_revision_ver')
  @revision=Revision_Sistematica[id]

  raise Buhos::NoReviewIdError, id if !@revision

  @searchs=@revision.busquedas
  @header=t_systematic_review_title(@revision[:nombre], :systematic_review_searchs)
  @user=Usuario[session['user_id']]

  $log.info(@user)

  @url_back="/review/#{id}/searchs"
  haml "systematic_reviews/searchs".to_sym
end

get '/review/:rs_id/searchs/user/:user_id' do |rs_id,user_id|
  error(403) unless permiso('busquedas_revision_ver')
  @revision=Revision_Sistematica[rs_id]

  raise Buhos::NoReviewIdError, rs_id if !@revision

  @user=Usuario[user_id]
  @header=t_systematic_review_title(@revision[:nombre], t(:searchs_user, :user_name=>Usuario[user_id][:nombre]), false)
  @url_back="/review/#{rs_id}/searchs/user/#{user_id}"
  @searchs=@revision.busquedas_dataset.where(:user_id=>user_id)
  haml "systematic_reviews/searchs".to_sym
end





get '/review/:id/search/new' do |id|
  error(403) unless permiso('busquedas_revision_crear')
  require 'date'

  @revision=Revision_Sistematica[id]
  raise Buhos::NoReviewIdError, id if !@revision

  @header=t_systematic_review_title(@revision[:nombre], :New_search)
  @bb_general_id=Base_Bibliografica[:nombre=>'generic'][:id]
  @search=Busqueda.new(:user_id=>session['user_id'], :source=>"database_search",:valid=>false, :fecha=>Date.today, :base_bibliografica_id=>@bb_general_id)
  @usuario=Usuario[session['user_id']]
  haml "searchs/search_edit".to_sym
end





get '/review/:rs_id/searchs/compare_records' do |rs_id|
  @revision=Revision_Sistematica[rs_id]
  raise Buhos::NoReviewIdError, rs_id if !@revision
  @cds={}
  @errores=[]
  @searchs_id=@revision.busquedas_dataset.map(:id)
  n_busquedas=@searchs_id.length
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
    #$log.info(@searchs_id)
    #$log.info(a)
    base_n=1+a[:busquedas].length*(2**(n_busquedas+1))
    #$log.info("Base:#{base_n}")
    sec_n=(0...n_busquedas).inject(0) {|total,aa|  total+=(a[:busquedas][@searchs_id[aa]].nil? ) ? 0 : 2**aa;total}
    #$log.info("Sec:#{sec_n}")
    base_n+sec_n
  }

  haml "searchs/compare_records".to_sym
end



get '/reviews' do
  halt_unless_auth('review_view')
  @usuario=User[session['user_id']]
  @show_inactives=params['show_inactives']
  @show_inactives||='only_actives'
  @show_only_user=params['show_only_user']
  @show_only_user||='yes'
  if @show_only_user=='yes'
    @reviewes=SystematicReview.get_revisiones_por_usuario(@usuario.id)
  else
    @reviewes=SystematicReview
  end


  @reviewes=@reviewes.where(:active => 1) if @show_inactives=='only_actives'


  haml :reviews
end


get '/review/new' do
  halt_unless_auth('review_edit')

  require 'date'
  title(t(:Systematic_review_new))
  first_group=User[session['user_id']].groups.first
  administrator=first_group[:group_administrator]
  @review=SystematicReview.new(      active:true,
                                     stage: "search",
                                     group:first_group,
                                     sr_administrator:administrator,
                                     date_creation: Date.today
                                     )
  @taxonomy_categories_id=[]

  haml %s{systematic_reviews/edit}
end


get "/review/:id" do |id|
  halt_unless_auth('review_view')

  @review=SystematicReview[id]
  ##$log.info(@names_trs)
  raise Buhos::NoReviewIdError, id if !@review
#  return 404 if !@review

  @taxonomy_categories=@review.taxonomy_categories_hash


  haml %s{systematic_reviews/view}
end

get "/review/:id/edit" do |id|
  halt_unless_auth('review_edit')

  @review=SystematicReview[id]
  raise Buhos::NoReviewIdError, id if !@review
  @taxonomy_categories_id=@review.taxonomy_categories_id
  title(t(:Systematic_review_edit, sr_name:@review.name))
  haml %s{systematic_reviews/edit}
end



post '/review/update' do
  halt_unless_auth('review_edit')

  id=params['review_id']
  otros_params=params
  otros_params.delete("review_id")
  otros_params.delete("captures")
  strc=params.delete("srtc")
  #No nulos
  ##$log.info(otros_params)
  otros_params=otros_params.inject({}) {|ac,v|
    ac[v[0].to_sym]=v[1];ac
  }
  #  aa=SystematicReview.new
  $log.info(otros_params)

  $db.transaction(:rollback=>:reraise) do
    if(id=="")
      id=SystematicReview.insert(otros_params)
    else
      revision=SystematicReview[id]
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



#### DOCUMENTOS CANONICOS #####

get '/review/:id/canonical_documents' do |id|
  halt_unless_auth('review_view')

  @review=SystematicReview[id]
  raise Buhos::NoReviewIdError, id if !@review

  @pager=get_pager

  @pager.order||="n_total_references_in__desc"

  @wo_abstract=params['wo_abstract']=='true'
  @only_records=params['only_records']=='true'

  @ars=AnalysisSystematicReview.new(@review)
  @cd_total_ds=@review.canonical_documents

  # Repetidos doi
  @cd_rep_doi=@review.doi_repetidos
  ##$log.info(@cd_rep_doi)

  @url="/review/#{id}/canonical_documents"
  @cds_pre=@review.canonical_documents.left_join(@review.count_references_bw_canonical, cd_id: Sequel[:canonical_documents][:id]).left_join(@review.count_references_rtr, cd_end: :cd_id)



  if @pager.query
    @cds_pre=@cds_pre.where(Sequel.ilike(:title, "%#{@pager.query}%"))
  end
  if @wo_abstract
    @cds_pre=@cds_pre.where(:abstract=>nil)
  end
  if @only_records
    @cds_pre=@cds_pre.where(:id=>@ars.cd_reg_id)
  end



  @cds_total=@cds_pre.count


  @pager.max_page=(@cds_total/@pager.cpp.to_f).ceil

#  $log.info(@pager)


  @order_criteria={:n_references_rtr=>I18n::t(:RTA_references), :n_total_references_in=>t(:Citations), :n_total_references_made=>t(:Outgoing_citations),  :title=>t(:Title), :year=> t(:Year), :author=>t(:Author)}


  @cds=@pager.adjust_query(@cds_pre)

  @ars=AnalysisSystematicReview.new(@review)


  haml %s{systematic_reviews/canonical_documents}
end


get '/review/:id/repeated_canonical_documents' do |id|
  halt_unless_auth('review_view')

  @review=SystematicReview[id]
  raise Buhos::NoReviewIdError, id if !@review
  @cd_rep_doi=@review.doi_repetidos
  @cd_hash=@review.canonical_documents.as_hash

  @cd_por_doi=CanonicalDocument.where(:doi => @cd_rep_doi).to_hash_groups(:doi, :id)
  ##$log.info(@cd_por_doi)
  haml %s{systematic_reviews/repeated_canonical_documents}
end


get '/review/:id/canonical_documents_graphml' do |id|
  halt_unless_auth('review_view')
  @review=SystematicReview[id]
  raise Buhos::NoReviewIdError, id if !@review
  headers["Content-Disposition"] = "attachment;filename=graphml_revision_#{id}.graphml"

  content_type 'application/graphml+xml'
  graphml=GraphML_Builder.new(@review, nil)
  graphml.generate_graphml
end




get '/review/:id/tags' do |id|
  halt_unless_auth('review_view')
  @review=SystematicReview[id]
  raise Buhos::NoReviewIdError, id if !@review
  @stages_list={:NIL=>"--Todas--"}.merge(get_stages_names_t)

  @select_stage=get_xeditable_select(@stages_list, "/tags/classes/edit_field/stage","select_stage")
  @select_stage.nil_value=:NIL
  @types_list={general:"General", document:"Documento", relation:"Relación"}

  @select_type=get_xeditable_select(@types_list, "/tags/classes/edit_field/type","select_type")

  @tag_estadisticas=@review.tags_estadisticas


  haml "systematic_reviews/tags".to_sym
end


get '/review/:id/messages' do |id|
  halt_unless_auth('review_view')
  @review=SystematicReview[id]
  raise Buhos::NoReviewIdError, id if !@review
  @mensajes_rs=@review.message_srs_dataset.order(Sequel.desc(:time))
  #@mensajes_rs_vistos=MessageSrSeen.where(:read=>true,:m_rs_id=>@mensajes_rs.select_map(:id), :user_id=>session['user_id']).select_map(:m_rs_id)
  #$log.info(@mensajes_rs_vistos)
  @usuario=User[session['user_id']]
  haml %s{systematic_reviews/messages}
end

post '/review/:id/message/new' do |id|
  halt_unless_auth('message_edit')
  @review=SystematicReview[id]
  raise Buhos::NoReviewIdError, id if !@review
  @user_id=params['user_id']
  return 404 if @review.nil? or @user_id.nil?
  @subject=params['subject']
  @text=params['text']
  $db.transaction(:rollback=>:reraise) do
    id=MessageSr.insert(:systematic_review_id=>id, :user_from=>@user_id, :reply_to=>nil, :time=>DateTime.now(), :subject=>@subject, :text=>@text)
    add_message(t("messages.new_message_for_sr", sr_name:@review[:name]))
  end
  redirect back
end

get '/review/:id/files' do |id|
  halt_unless_auth('review_view', 'file_view')
  @review=SystematicReview[id]
  raise Buhos::NoReviewIdError, id if !@review
  @file_rs=IFile.join(:file_srs, :file_id => :id).left_join(:file_cds, :file_id => :file_id).where(:systematic_review_id => id).order_by(:filename)
  @modal_files=get_modal_files

  @canonical_documents_h=@review.canonical_documents.order(:title).as_hash
  @cd_validos_id=@review.cd_id_by_stage(@review.stage)
  @cd_validos=@canonical_documents_h.find_all {|v| @cd_validos_id.include? v[0]}.map{|v| v[1]}
  @usuario=User[session['user_id']]
  haml %s{systematic_reviews/files}
end

post '/review/files/add' do
  halt_unless_auth('review_edit', 'file_admin')

  #$log.info(params)
  @review=SystematicReview[params['systematic_review_id']]
  raise Buhos::NoReviewIdError, id if !@review
  files=params['files']
  cd=nil
  cd_id=params['canonical_document_id']
  if cd_id
    cd=CanonicalDocument[cd_id]
    return 404 if cd.nil?
  end

  if files
    results=Result.new
    files.each do |file|
      results.add_result(IFile.add_on_sr(file,@review,dir_files,cd))
    end
    add_result results
  else
    add_message(I18n::t(:Files_not_uploaded), :error)
  end
  redirect back
end


get '/review/:id/advance_stage' do |id|
  halt_unless_auth('review_admin')

  @review=SystematicReview[id]
  raise Buhos::NoReviewIdError, id if !@review

  @ars=AnalysisSystematicReview.new(@review)
  if (@ars.stage_complete?(@review.stage))
    stage_i=get_stages_ids.index(@review[:stage].to_sym)
    #$log.info(stage_i)
    return 405 if stage_i.nil?
    @review.update(:stage=>get_stages_ids[stage_i+1])
    add_message(I18n::t(:stage_complete))
    redirect("/review/#{@review[:id]}/administration/#{@review[:stage]}")
  else
    add_message(I18n::t(:stage_not_yet_complete), :error)
    redirect back
  end
end
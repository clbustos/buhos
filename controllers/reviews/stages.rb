get '/review/:id/screening_title_abstract' do |id|
  halt_unless_auth('review_analyze')
  @review=SystematicReview[id]
  raise Buhos::NoReviewIdError, id if !@review

  @usuario=User[session['user_id']]
  @user_id=@usuario[:id]


  @pager=get_pager
  @pager.order||="year__asc"


  @order_criteria={:title=>I18n.t(:Title), :year=> I18n.t(:Year), :author=>I18n.t(:Author)}

  # $log.info(params)


  @stage='screening_title_and_abstract'
  @ars=AnalysisSystematicReview.new(@review)
  @cd_total_ds=@review.canonical_documents


  @url="/review/#{id}/screening_title_abstract"

  @ads=AnalysisUserDecision.new(id, @user_id, 'screening_title_abstract')

  @cds_pre=@ads.canonical_documents
  @cds_total=@cds_pre.count

  @decisions=@ads.decisions
  if @pager.query.to_s!=""
    cd_ids=@ads.decision_por_cd.find_all {|v|
      @pager.query==v[1]
    }.map {|v| v[0]}
    @cds_pre=@cds_pre.where(:id => cd_ids)
  end




  @pager.max_page=(@cds_pre.count/@pager.cpp.to_f).ceil

  @cds=@pager.adjust_query(@cds_pre)


  haml "systematic_reviews/screening_general".to_sym

end


get '/review/:id/screening_references' do |id|
  halt_unless_auth('review_analyze')

  @review=SystematicReview[id]
  raise Buhos::NoReviewIdError, id if !@review

  @usuario=User[session['user_id']]
  @user_id=@usuario[:id]


  @pager=get_pager()
  @pager.order||="n_references_rtr__desc"


  @order_criteria={:n_references_rtr=>I18n.t(:RTA_references), :title=>I18n.t(:Title), :year=> I18n.t(:Year), :author=>I18n.t(:Author)}

  # $log.info(params)
  @stage='screening_references'


  @ars=AnalysisSystematicReview.new(@review)
  @cd_total_ds=@review.canonical_documents


  @url="/review/#{id}/screening_references"

  @ads=AnalysisUserDecision.new(id, @user_id, 'screening_references')

  @cds_pre=@ads.canonical_documents.join_table(:inner, @review.count_references_rtr_tn.to_sym, cd_end: :id)


  @decisions=@ads.decisions
  @cds_total=@cds_pre.count

  if @pager.query.to_s!=""
    cd_ids=@ads.decision_por_cd.find_all {|v|
      @pager.query==v[1]
    }.map {|v| v[0]}
    @cds_pre=@cds_pre.where(:id => cd_ids)
  end




  @pager.max_page=(@cds_pre.count/@pager.cpp.to_f).ceil

  @cds=@pager.adjust_query(@cds_pre)


  haml "systematic_reviews/screening_general".to_sym

end


get '/review/:id/review_full_text' do |id|
  halt_unless_auth('review_analyze')
  @review=SystematicReview[id]
  raise Buhos::NoReviewIdError, id if !@review


  @usuario=User[session['user_id']]
  @user_id=@usuario[:id]


  @pager=get_pager()
  @pager.order||="year__asc"


  @order_criteria={:n_references_rtr=>I18n.t(:RTA_references), :title=>I18n.t(:Title), :year=> I18n.t(:Year), :author=>I18n.t(:Author)}

  # $log.info(params)

  @ars=AnalysisSystematicReview.new(@review)
  @cd_total_ds=@review.canonical_documents


  @url="/review/#{id}/review_full_text"

  @ads=AnalysisUserDecision.new(id, @user_id, 'review_full_text')

  @cds_pre=@ads.canonical_documents.join_table(:left, @review.count_references_rtr_tn.to_sym, cd_end: :id)

  @asignaciones=@ads.asignaciones.to_hash(:canonical_document_id)

  @decisions=@ads.decisions
  @cds_total=@cds_pre.count

  if @pager.query.to_s!=""
    cd_ids=@ads.decision_por_cd.find_all {|v|
      @pager.query==v[1]
    }.map {|v| v[0]}
    @cds_pre=@cds_pre.where(:id => cd_ids)
  end




  @pager.max_page=(@cds_pre.count/@pager.cpp.to_f).ceil

  @cds=@pager.adjust_query(@cds_pre)


  haml %s{systematic_reviews/review_full_text}
end





get '/review/:rev_id/stage/:stage/generate_graphml' do |rev_id, stage|
  halt_unless_auth('review_view')
  @review=SystematicReview[rev_id]
  raise Buhos::NoReviewIdError, rev_id if !@review
  headers["Content-Disposition"] = "attachment;filename=graphml_revision_#{rev_id}_stage_#{stage}.graphml"

  content_type 'application/graphml+xml'
  graphml=GraphML_Builder.new(@review, stage)
  graphml.generate_graphml
end

get '/review/:rev_id/stage/:stage/generate_bibtex' do |rev_id, stage|
  halt_unless_auth('review_view')
  @review=SystematicReview[rev_id]
  raise Buhos::NoReviewIdError, rev_id if !@review
  canonicos_id=@review.cd_id_by_stage(stage)
  @canonicos_resueltos=CanonicalDocument.where(:id=>canonicos_id).order(:author,:year)

  bib=ReferenceIntegrator::BibTex::Writer.generate(@canonicos_resueltos)
  headers["Content-Disposition"] = "attachment;filename=systematic_review_#{rev_id}_#{stage}.bib"
  content_type 'text/x-bibtex'
  bib.to_s

end


get '/review/:rev_id/stage/:stage/generate_doi_list' do |rev_id, stage|
  halt_unless_auth('review_view')
  @review=SystematicReview[rev_id]
  raise Buhos::NoReviewIdError, rev_id if !@review
  canonicos_id=@review.cd_id_by_stage(stage)
  @canonicos_resueltos=CanonicalDocument.where(:id=>canonicos_id).order(:author,:year).exclude(:doi=>nil)
  dois=@canonicos_resueltos.map {|v| v.doi}.join("\n")

#  headers["Content-Disposition"] = "attachment;filename=systematic_review_#{rev_id}_#{stage}.bib"
  content_type 'text/plain'
  dois

end

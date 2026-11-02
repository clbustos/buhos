# Buhos
# https://github.com/clbustos/buhos
# Copyright (c) 2016-2025, Claudio Bustos Navarrete
# All rights reserved.
# Licensed BSD 3-Clause License
# See LICENSE file for more information
#

# @!group Screening and analysis of documents


# Reuse the reviewer panels without changing the administrator's session.
helpers do
  def stage_panel_user(preview_user_id)
    if preview_user_id
      halt_unless_auth_any('review_admin', 'review_admin_view')
      @preview_user=(@review.group_users || []).find {|user| user.id.to_s==preview_user_id.to_s}
      halt 404 unless @preview_user
      @preview_user
    else
      halt_unless_auth('review_analyze')
      User[session['user_id']]
    end
  end

  def render_stage_panel(template)
    return haml(template, escape_html: false) unless @preview_user

    # The preview is a static snapshot: embedded scripts and forms cannot run.
    headers 'Content-Security-Policy' => "sandbox allow-same-origin",
            'Cache-Control' => 'no-store'
    @preview_panel=haml(template, layout: false, escape_html: false)
    haml :stage_panel_preview, escape_html: false
  end
end

# Interface for stage screening titles and abstract
screening_title_abstract_panel=proc do |id, preview_user_id=nil|
  @review=SystematicReview[id]
  raise Buhos::NoReviewIdError, id if !@review

  @usuario=stage_panel_user(preview_user_id)
  @user_id=@usuario[:id]


  @pager=get_pager([:decision])
  @pager.order||="year__asc"
  @blind_reference_screening=@review.blind_reference_screening?
  @pager.order="title__asc" if @blind_reference_screening && @pager.order !~ /^title__/
  @order_criteria=@blind_reference_screening ? {:title=>I18n.t(:Title)} : {:title=>I18n.t(:Title), :year=> I18n.t(:Year), :author=>I18n.t(:Author)}

  # $log.info(params)


  @stage='screening_title_abstract'
  @ars=AnalysisSystematicReview.new(@review)
  @cd_total_ds=@review.canonical_documents


  @url="/review/#{id}/#{@stage}"

  @ads=AnalysisUserDecision.new(id, @user_id,@stage)



  @cds_pre=@ads.canonical_documents
  @cds_total=@cds_pre.count
  @decisions=@ads.decisions
  @favorites = FavoriteDocument.where(user_id: @user_id, activo: true).
    inject({}) {|ac,v| ac[v[:canonical_document_id]]=v; ac}
  begin
    @cds=@pager.adapt_ads_cds(@ads, @cds_pre)
  rescue Buhos::SearchParser::ParsingError => e
    add_message(e.message,:error )
    params['query']=nil
    @cds=@pager.adapt_ads_cds(@ads, @cds_pre, no_query:true)
  end

  render_stage_panel(:"systematic_reviews/screening_general")

end

get '/review/:id/screening_title_abstract', &screening_title_abstract_panel
get '/review/:id/screening_title_abstract/preview/:preview_user_id', &screening_title_abstract_panel

# Inteface for stage screening references

screening_references_panel=proc do |id, preview_user_id=nil|

  @review=SystematicReview[id]
  raise Buhos::NoReviewIdError, id if !@review

  @usuario=stage_panel_user(preview_user_id)
  @user_id=@usuario[:id]


  @pager=get_pager([:decision])
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


  begin
    @cds=@pager.adapt_ads_cds(@ads, @cds_pre)
  rescue Buhos::SearchParser::ParsingError => e
    add_message(e.message,:error )
    params['query']=nil
    @cds=@pager.adapt_ads_cds(@ads, @cds_pre, no_query:true)
  end
  #  @favorites = FavoriteDocument.where(user_id: @user_id)
  #                               .to_hash(:canonical_document_id, :commentary)
  #$log.info(@pager)

  render_stage_panel(:"systematic_reviews/screening_general")

end

get '/review/:id/screening_references', &screening_references_panel
get '/review/:id/screening_references/preview/:preview_user_id', &screening_references_panel

# Inteface for stage review full text

review_full_text_panel=proc do |id, preview_user_id=nil|
  @review=SystematicReview[id]
  raise Buhos::NoReviewIdError, id if !@review


  @user=stage_panel_user(preview_user_id)
  @user_id=@user[:id]


  @pager=get_pager([:decision, :tag_select, :search_title])
  @pager.order||="year__asc"


  @order_criteria={:n_references_rtr=>I18n.t(:RTA_references), :title=>I18n.t(:Title), :year=> I18n.t(:Year), :author=>I18n.t(:Author)}
  @stage=Buhos::Stages::STAGE_REVIEW_FULL_TEXT.to_s

  @ars=AnalysisSystematicReview.new(@review)
  @cd_total_ds=@review.canonical_documents
  @modal_files=get_modal_files
  @files_by_cd=@ars.files_by_cd
  @global_files_by_cd=@ars.global_files_by_cd


  @url="/review/#{id}/#{@stage}"

  @ads=AnalysisUserDecision.new(id, @user_id, @stage)

  @cds_pre=@ads.canonical_documents.join_table(:left, @review.count_references_rtr_tn.to_sym, cd_end: :id)

  @assignations=@ads.assignations.to_hash(:canonical_document_id)

  @decisions=@ads.decisions
  @cds_total=@cds_pre.count


  begin
    @cds=@pager.adapt_ads_cds(@ads, @cds_pre)
  rescue Buhos::SearchParser::ParsingError => e
    add_message(e.message,:error )
    params['query']=nil
    @cds=@pager.adapt_ads_cds(@ads, @cds_pre, no_query:true)
  end

  @a_tags=Buhos::AnalysisTags.new
  @a_tags.systematic_review_id(@review.id)
  @a_tags.user_id(@user_id)
  render_stage_panel(:"systematic_reviews/review_full_text")
end

get '/review/:id/review_full_text', &review_full_text_panel
get '/review/:id/review_full_text/preview/:preview_user_id', &review_full_text_panel

# Interface for extraction and quality assessment after full-text review
extract_information_panel=proc do |id, preview_user_id=nil|
  @review=SystematicReview[id]
  raise Buhos::NoReviewIdError, id if !@review

  @user=stage_panel_user(preview_user_id)
  @user_id=@user[:id]
  @stage=Buhos::Stages::STAGE_REVIEW_EXTRACT_INFORMATION.to_s

  @pager=get_pager([:tag_select, :search_title])
  @pager.order||="year__asc"
  @order_criteria={:n_references_rtr=>I18n.t(:RTA_references), :title=>I18n.t(:Title), :year=> I18n.t(:Year), :author=>I18n.t(:Author)}

  @ars=AnalysisSystematicReview.new(@review)
  @extract_information_stats=Analysis_SR_Stage.new(@review, @stage).extract_information_stats
  @extract_information_document_statuses=@extract_information_stats[:document_statuses].each_with_object({}) do |status, memo|
    memo[status[:canonical_document_id]]=status
  end
  @cd_total_ds=@review.canonical_documents
  @url="/review/#{id}/#{@stage}"

  @ads=AnalysisUserDecision.new(id, @user_id, @stage)
  @cds_pre=@ads.canonical_documents.join_table(:left, @review.count_references_rtr_tn.to_sym, cd_end: :id)
  @assignations=@ads.assignations.to_hash(:canonical_document_id)
  @cds_total=@cds_pre.count

  begin
    @cds=@pager.adapt_ads_cds(@ads, @cds_pre)
  rescue Buhos::SearchParser::ParsingError => e
    add_message(e.message,:error )
    params['query']=nil
    @cds=@pager.adapt_ads_cds(@ads, @cds_pre, no_query:true)
  end

  @a_tags=Buhos::AnalysisTags.new
  @a_tags.systematic_review_id(@review.id)
  @a_tags.user_id(@user_id)
  render_stage_panel(:"systematic_reviews/extract_information")
end

get '/review/:id/extract_information', &extract_information_panel
get '/review/:id/extract_information/preview/:preview_user_id', &extract_information_panel


# @!endgroup

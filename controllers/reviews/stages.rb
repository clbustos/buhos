# Buhos
# https://github.com/clbustos/buhos
# Copyright (c) 2016-2025, Claudio Bustos Navarrete
# All rights reserved.
# Licensed BSD 3-Clause License
# See LICENSE file for more information
#

# @!group Screening and analysis of documents


# Interface for stage screening titles and abstract
get '/review/:id/screening_title_abstract' do |id|
  halt_unless_auth('review_analyze')
  @review=SystematicReview[id]
  raise Buhos::NoReviewIdError, id if !@review

  @usuario=User[session['user_id']]
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
  $log.info(@favorites)
  begin
    @cds=@pager.adapt_ads_cds(@ads, @cds_pre)
  rescue Buhos::SearchParser::ParsingError => e
    add_message(e.message,:error )
    params['query']=nil
    @cds=@pager.adapt_ads_cds(@ads, @cds_pre, no_query:true)
  end

  haml "systematic_reviews/screening_general".to_sym, escape_html: false

end

# Inteface for stage screening references

get '/review/:id/screening_references' do |id|
  halt_unless_auth('review_analyze')

  @review=SystematicReview[id]
  raise Buhos::NoReviewIdError, id if !@review

  @usuario=User[session['user_id']]
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

  haml "systematic_reviews/screening_general".to_sym, escape_html: false

end

# Inteface for stage review full text

get '/review/:id/review_full_text' do |id|
  halt_unless_auth('review_analyze')
  @review=SystematicReview[id]
  raise Buhos::NoReviewIdError, id if !@review


  @user=User[session['user_id']]
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
  haml %s{systematic_reviews/review_full_text}, escape_html: false
end

# Interface for extraction and quality assessment after full-text review
get '/review/:id/extract_information' do |id|
  halt_unless_auth('review_analyze')
  @review=SystematicReview[id]
  raise Buhos::NoReviewIdError, id if !@review

  @user=User[session['user_id']]
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
  haml %s{systematic_reviews/extract_information}, escape_html: false
end


# @!endgroup

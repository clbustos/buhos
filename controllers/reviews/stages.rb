# Buhos
# https://github.com/clbustos/buhos
# Copyright (c) 2016-2018, Claudio Bustos Navarrete
# All rights reserved.
# Licensed BSD 3-Clause License
# See LICENSE file for more information
#

# @!group Screening and analysis of documents


# Inteface for stage screening titles and abstract
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


  @stage='screening_title_abstract'
  @ars=AnalysisSystematicReview.new(@review)
  @cd_total_ds=@review.canonical_documents


  @url="/review/#{id}/#{@stage}"

  @ads=AnalysisUserDecision.new(id, @user_id,@stage)

  $log.info(@ads)
 # $log.info("HOAL")

  @cds_pre=@ads.canonical_documents
  @cds_total=@cds_pre.count

  @decisions=@ads.decisions
  # if @pager.query.to_s!=""
  #   cd_ids=@ads.decision_por_cd.find_all {|v|
  #     @pager.query==v[1]
  #   }.map {|v| v[0]}
  #   @cds_pre=@cds_pre.where(:id => cd_ids)
  # end

  @cds_pre=@pager.adapt_cd_dataset(@ads, @cds_pre)


  @pager.max_page=(@cds_pre.count/@pager.cpp.to_f).ceil

  @cds=@pager.adjust_query(@cds_pre)


  haml "systematic_reviews/screening_general".to_sym

end

# Inteface for stage screening references

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


  @cds_pre=@pager.adapt_cd_dataset(@ads, @cds_pre)


  @pager.max_page=(@cds_pre.count/@pager.cpp.to_f).ceil

  @cds=@pager.adjust_query(@cds_pre)


  haml "systematic_reviews/screening_general".to_sym

end

# Inteface for stage review full text

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


  @cds_pre=@pager.adapt_cd_dataset(@ads, @cds_pre)

  @pager.max_page=(@cds_pre.count/@pager.cpp.to_f).ceil

  @cds=@pager.adjust_query(@cds_pre)


  haml %s{systematic_reviews/review_full_text}
end


# @!endgroup



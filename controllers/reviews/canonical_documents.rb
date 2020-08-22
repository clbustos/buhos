# Buhos
# https://github.com/clbustos/buhos
# Copyright (c) 2016-2018, Claudio Bustos Navarrete
# All rights reserved.
# Licensed BSD 3-Clause License
# See LICENSE file for more information


# @!group canonical documents assigned to reviews

# List of canonical documents of a review
get '/review/:id/canonical_documents' do |id|
  halt_unless_auth('review_view')

  @review=SystematicReview[id]
  raise Buhos::NoReviewIdError, id if !@review

  @pager=get_pager

  @pager.cpp=20
  @pager.order||="n_total_references_in__desc"

  @wo_abstract=params['wo_abstract']=='true'
  @only_records=params['only_records']=='true'

  @ars=AnalysisSystematicReview.new(@review)
  @cd_total_ds=@review.canonical_documents

  # Repetidos doi
  @dup_analysis=Buhos::DuplicateAnalysis.new(@cd_total_ds)

  @cd_rep_doi=@dup_analysis.by_doi
  ##$log.info(@cd_rep_doi)

  @url="/review/#{id}/canonical_documents"
  @cds_pre=@review.canonical_documents.left_join(@review.count_references_bw_canonical, cd_id: Sequel[:canonical_documents][:id]).left_join(@review.count_references_rtr, cd_end: :cd_id)



  if @pager.query
    # Code por pager

    begin
      sp=Buhos::SearchParser.new
      if @pager.query=~/\(.+\)/
        sp.parse(@pager.query)
      else
        sp.parse("title(\"#{@pager.query}\")")
      end
      @cds_pre=@cds_pre.where(Sequel.lit(sp.to_sql))
    rescue Buhos::SearchParser::ParsingError=> e
      add_message(e.message, :error)
    end
    #
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


  @cds=@pager.adjust_page_order(@cds_pre)

  @ars=AnalysisSystematicReview.new(@review)
  @user=User[session['user_id']]

  @tags_a=Buhos::AnalysisTags.new
  @tags_a.systematic_review_id(@review.id)

  #$log.info($db[:canonical_documents].all)
  #$log.info(@cds.all)

  haml %s{systematic_reviews/canonical_documents}
end


get "/review/:sr_id/canonical_documents/tags" do |sr_id|
  sr_tags_prev(sr_id)

  haml "tags/rs_cds_massive".to_sym


end


post "/review/:sr_id/canonical_documents/tags/actions" do |sr_id|
  sr_tags_prev(sr_id)
  action=params['action']
  result=Result.new



  if action=='add_for_all' or action=='remove_for_all'
    unless params['tags_all']
      add_message(t(:No_tag_defined), :error)
      redirect back
    end
    params['tags_all'].map(&:to_i).each do |tag_id|
      tag=Tag[tag_id]
      raise Buhos::NoTagIdError tag_id unless tag
      if action=='add_for_all'
        result.add_result(TagInCd.approve_tag_batch(@cds,@review,tag,@user_id))
      else
        result.add_result(TagInCd.reject_tag_batch(@cds,@review,tag,@user_id))
      end
    end
  elsif action=='add_new'
    unless params['new_tags'].chomp!=""
      add_message(t(:No_tag_defined), :error)
      redirect back
    end
    tag=Tag.get_tag(params['new_tags'].chomp)
    raise Buhos::NoTagIdError tag_id unless tag
    result.add_result(TagInCd.approve_tag_batch(@cds,@review,tag,@user_id))
  else
    raise "#{t(:Action_not_defined)}:#{action}"
  end
  add_result(result)
  redirect back
end



get "/review/:sr_id/canonical_document/:cd_id" do |sr_id, cd_id|
  halt_unless_auth('review_view')
  @sr_id=sr_id
  @cd_id=cd_id
  @review=SystematicReview[@sr_id]
  raise Buhos::NoReviewIdError, sr_id if !@review
  @cd=CanonicalDocument[@cd_id]
  raise Buhos::NoCdIdError, cd_id if !@cd

  title(t(:canonical_document_title, cd_title:@cd.ref_apa_6))


  @rs_cds=@review.cd_hash


  # TODO: Should be refactored on independent method
  @records= Record.where(id:$db["SELECT rs.record_id from records_searches rs INNER JOIN searches s ON rs.search_id=s.id WHERE s.valid=1 AND s.systematic_review_id=?", @review.id].map(:record_id), canonical_document_id:@cd_id).order(:author, :year)

  @references=Reference.where(id:$db["SELECT  DISTINCT(rr.reference_id) as ref_id  FROM records_references rr INNER JOIN records_searches rs ON rr.record_id=rs.record_id INNER JOIN searches s ON rs.search_id=s.id WHERE s.valid=1 and s.systematic_review_id=?", @review.id].map(:ref_id),  canonical_document_id:@cd_id).order(:text)

  if CrossrefDoi[doi_without_http(@cd.doi)]
    @cr_doi=@cd.crossref_integrator
  end


  if Pmc_Summary[@cd.pmid]
    @pmc_sum=@cd.pubmed_integrator
  end

  @asr=AnalysisSystematicReview.new(@review)

  @sim_all=Buhos::SimilarAnalysisSr.similar_to_cd_in_sr( cd:@cd, sr:@review)
  @references_realizadas=@cd.references_performed
  haml :canonical_document

end

get %r{/review/(\d+)/canonical_document/(\d+)/(cites|cited_by|cited_by_rtr)} do
  halt_unless_auth('review_view')
  @sr_id=params[:captures][0]
  @cd_id=params[:captures][1]
  @type=params[:captures][2]
  @sr=SystematicReview[@sr_id]
  raise Buhos::NoReviewIdError, sr_id if !@sr
  @cd=CanonicalDocument[@cd_id]
  raise Buhos::NoCdIdError, @cd_id if !@cd
  @rwc= AnalysisSystematicReview.reference_between_canonicals(@sr)
  @cd_to_show=@rwc.send(@type.to_sym, @cd_id)
  haml "systematic_reviews/canonical_document_cites".to_sym
end


# Get a list of repeated canonical documents, using DOI
# @todo Check another ways to deduplicate
get '/review/:id/repeated_canonical_documents' do |id|
  halt_unless_auth('review_view')

  @review=SystematicReview[id]
  raise Buhos::NoReviewIdError, id if !@review
  @cds=@review.canonical_documents
  @dup_analysis=Buhos::DuplicateAnalysis.new(@cds)

  @cd_rep_doi=@dup_analysis.by_doi
  @cd_rep_metadata=@dup_analysis.by_metadata
  @cd_hash=@cds.to_hash(:id)

  @cd_por_doi=CanonicalDocument.where(:doi => @cd_rep_doi).to_hash_groups(:doi, :id)

  @cd_por_doi=CanonicalDocument.where(:doi => @cd_rep_doi).to_hash_groups(:doi, :id)


  ##$log.info(@cd_por_doi)
  haml %s{systematic_reviews/repeated_canonical_documents}
end


# @!endgroup

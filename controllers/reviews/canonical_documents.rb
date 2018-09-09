# Buhos
# https://github.com/clbustos/buhos
# Copyright (c) 2016-2018, Claudio Bustos Navarrete
# All rights reserved.
# Licensed BSD 3-Clause License
# See LICENSE file for more information


# @!group canonical documents assigned to reviews

get "/review/:sr_id/canonical_document/:cd_id" do |sr_id, cd_id|
  halt_unless_auth('review_view')
  @sr_id=sr_id
  @cd_id=cd_id
  @review=SystematicReview[@sr_id]
  raise Buhos::NoReviewIdError, sr_id if !@review
  @cd=CanonicalDocument[@cd_id]
  raise Buhos::NoCdIdError, cd_id if !@cd

  @rs_cds=@review.cd_hash


  @records= Record.where(id:$db["SELECT rs.record_id from records_searches rs INNER JOIN searches s ON rs.search_id=s.id WHERE s.valid=1 AND s.systematic_review_id=?", @review.id].map(:record_id), canonical_document_id:@cd_id).order(:author, :year)

  @references=Reference.where(id:$db["SELECT  DISTINCT(rr.reference_id) as ref_id  FROM records_references rr INNER JOIN records_searches rs ON rr.record_id=rs.record_id INNER JOIN searches s ON rs.search_id=s.id WHERE s.valid=1 and s.systematic_review_id=?", @review.id].map(:ref_id),  canonical_document_id:@cd_id).order(:text)

  if CrossrefDoi[doi_without_http(@cd.doi)]
    @cr_doi=@cd.crossref_integrator
  end


  if Pmc_Summary[@cd.pmid]
    @pmc_sum=@cd.pubmed_integrator
  end


  title(t(:canonical_document_title, cd_title:@cd.ref_apa_6))

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
  raise Buhos::NoCdIdError, cd_id if !@cd
  @rwc= AnalysisSystematicReview.reference_between_canonicals(@sr)
  @cd_to_show=@rwc.send(@type.to_sym, @cd_id)
  haml "systematic_reviews/canonical_document_cites".to_sym
end

# @!endgroup
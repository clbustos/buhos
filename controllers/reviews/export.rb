# Buhos
# https://github.com/clbustos/buhos
# Copyright (c) 2016-2025, Claudio Bustos Navarrete
# All rights reserved.
# Licensed BSD 3-Clause License
# See LICENSE file for more information



# @!group Export

# Generate a GraphML file of all documents on a systematic review.
# Warning: Could be very big!
# @see http://graphml.graphdrawing.org/ GraphML website
# @see '/review/:rev_id/stage/:stage/generate_graphml'

get '/review/:id/generate_graphml' do |id|
  halt_unless_auth('review_view')
  @review=SystematicReview[id]
  raise Buhos::NoReviewIdError, id if !@review
  headers["Content-Disposition"] = "attachment;filename=graphml_revision_#{id}.graphml"

  content_type 'application/graphml+xml'
  graphml=Buhos::GraphML_Builder.new(@review, nil)
  graphml.generate_graphml
end


# Generate a GraphML file of documents on a specific stage.
# @see http://graphml.graphdrawing.org/ GraphML website
#
get '/review/:rev_id/stage/:stage/generate_graphml' do |rev_id, stage|
  halt_unless_auth('review_view')
  @review=SystematicReview[rev_id]
  raise Buhos::NoReviewIdError, rev_id if !@review

  graphml=Buhos::GraphML_Builder.new(@review, stage)
  graphml.prepare_stream(self)
  graphml.generate_graphml
end


get '/review/:rev_id/generate_excel' do |rev_id|
  halt_unless_auth('review_view')
  @review=SystematicReview[rev_id]
  raise Buhos::NoReviewIdError, rev_id if !@review
  eb=Buhos::ExcelBuilder.new(@review,nil)
  eb.generate_excel(true)
  eb.prepare_stream(self)
  eb.stream
end
# Generate a Excel file of documents on a specific stage
#

get '/review/:rev_id/stage/:stage/generate_excel' do |rev_id, stage|
  halt_unless_auth('review_view')
  @review=SystematicReview[rev_id]
  raise Buhos::NoReviewIdError, rev_id if !@review
  eb=Buhos::ExcelBuilder.new(@review, stage)
  eb.generate_excel(true)
  eb.prepare_stream(self)
  eb.stream
end


get '/review/:rev_id/generate_bibtex' do |rev_id|
  halt_unless_auth('review_view')
  @review=SystematicReview[rev_id]
  raise Buhos::NoReviewIdError, rev_id if !@review
  canonicos_id=@review.cd_all_id
  @canonicos_resueltos=CanonicalDocument.where(:id=>canonicos_id).order(:author,:year)
  bib=BibliographicalImporter::BibTex::Writer.generate(@canonicos_resueltos)
  headers["Content-Disposition"] = "attachment;filename=systematic_review_#{rev_id}_all.bib"
  content_type 'text/x-bibtex'
  bib.to_s

end

# Generate a BibTeX file of documents on a specific stage
#

get '/review/:rev_id/stage/:stage/generate_bibtex' do |rev_id, stage|
  halt_unless_auth('review_view')
  @review=SystematicReview[rev_id]
  raise Buhos::NoReviewIdError, rev_id if !@review
  canonicos_id=@review.cd_id_by_stage(stage)
  @canonicos_resueltos=CanonicalDocument.where(:id=>canonicos_id).order(:author,:year)

  bib=BibliographicalImporter::BibTex::Writer.generate(@canonicos_resueltos)
  headers["Content-Disposition"] = "attachment;filename=systematic_review_#{rev_id}_#{stage}.bib"
  content_type 'text/x-bibtex'
  bib.to_s

end



# Generate a list of DOI of documents on a specific stage
#

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


# @!endgroup
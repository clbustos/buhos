# Encoding:UTF-8

# Buhos
# https://github.com/clbustos/buhos
# Copyright (c) 2016-2022, Claudio Bustos Navarrete
# All rights reserved.
# Licensed BSD 3-Clause License
# See LICENSE file for more information

# @!group Searches


# List of searches
get '/review/:id/searches' do |id|
  halt_unless_auth('review_view')
  @review=SystematicReview[id]

  raise Buhos::NoReviewIdError, id if !@review

  @searches=@review.searches
  @header=t_systematic_review_title(@review[:name], :systematic_review_searches)
  @user=User[session['user_id']]

  #$log.info(@user)

  @url_back="/review/#{id}/searches"
  haml "systematic_reviews/searches".to_sym, escape_html: false
end




get %r{/review/(\d+)/searches/analyze(?:/(.*))?} do
  sr_id, search_ids=params['captures']
  @review=SystematicReview[sr_id]
  raise Buhos::NoReviewIdError, sr_id if !@review

  if search_ids.to_s!=""
    @searches=Search.where(:id=>search_ids.split(","))
  else
    @searches=Search.where(:systematic_review_id=>sr_id)
  end




  @an_searches=Buhos::AnalysisSearches.new(@searches)
  @searches_id=@an_searches.searches_id.join(", ")
  haml "searches/analyze".to_sym, escape_html: false


end

get %r{/review/(\d+)/(?:searches/)?records(?:/user/(\d+))?} do
  halt_unless_auth('record_view')
  review_id, user_id=params['captures']
  @review=SystematicReview[review_id]
  raise Buhos::NoReviewIdError, review_id if !@review
  records_base=Record.select(:record_id, :search_id, :canonical_document_id).join(:records_searches, record_id: :id).join(:searches, id: :search_id).distinct
  if user_id
    @users=nil
    @user=User[user_id]
    @records=records_base.where(systematic_review_id:review_id, user_id:user_id)
    @sv=SearchValidatorUser.new(@review, @user)
  else
    @user=nil
    @records=records_base.where(systematic_review_id:review_id)
    @users=@records.map {|v| v[:user_id]}.uniq
    @sv=SearchValidatorReview.new(@review)
  end
  @sv.validate
  @cds=CanonicalDocument.where(:id=>@records.map {|v| v[:canonical_document_id]}.uniq).to_hash

#  $log.info(@cds)
  haml "searches/records".to_sym, escape_html: false
end

get '/review/:review_id/search/:search_id/record/:record_id/complete_information' do |review_id, search_id, record_id|
  @review=SystematicReview[review_id]
  raise Buhos::NoReviewIdError, review_id if !@review
  @search=Search[search_id]
  raise Buhos::NoSearchIdError, search_id if !@search
  @record=Record[record_id]
  raise Buhos::NoRecordIdError, record_id if !@record
  @record_search=RecordsSearch[record_id: record_id, search_id:search_id ]
  raise Buhos::NoRecordSearchIdError, [record_id, search_id] if !@record_search
  @cd=@record.canonical_document
  @user=User[params['user_id']]


  @current_file=get_file_canonical_document(@review,@cd)

  haml "searches/record_complete_information".to_sym, escape_html: false

end
get '/review/:id/search/uploaded_files/new' do |id|

  halt_unless_auth('search_edit')
  @review=SystematicReview[id]
  raise Buhos::NoReviewIdError, id if !@review
  haml "searches/search_uploaded_files".to_sym, escape_html: false
end



post '/review/search/uploaded_files/new' do

  halt_unless_auth('review_edit', 'file_admin')

  @bb_general_id=BibliographicDatabase[:name=>'generic'][:id]

  @review=SystematicReview[params['systematic_review_id']]
  raise Buhos::NoReviewIdError, id if !@review
  files=params['files']
  cds_id=[]

  $db.transaction do

    search_id=Search.insert(:systematic_review_id=>@review.id,:description=>params["description"],
                            :filetype=>'text/plain', :source=>params['source'], :valid=>false,
                            :user_id=>session['user_id'], :date_creation=>Date.today,
                            :bibliographic_database_id=>@bb_general_id,
                            :search_type=>'uploaded_files')
    search=Search[search_id]
    if files
      results=Result.new
      files.each do |file|
        next if file[:type]!~/pdf/ and file[:filename]!~/\.pdf/
        pdfprocessor=PdfFileProcessor.new(search, file[:tempfile], dir_files)
        pdfprocessor.process
        results.add_result(pdfprocessor.results)
        cds_id.push(pdfprocessor.canonical_document.id)
      end
      add_result results
    else
      add_message(I18n::t(:Files_not_uploaded), :error)
    end
    search.update(:file_body=>cds_id.join("\n"))

    redirect url("/review/#{@review.id}/dashboard")
  end
  add_message(I18n::t("error.problem_uploading_files"), :error)
  redirect back
end


# Form to create a new search based on bibliographic files
get '/review/:id/search/bibliographic_file/new' do |id|
  halt_unless_auth('search_edit')

  require 'date'

  @review=SystematicReview[id]
  raise Buhos::NoReviewIdError, id if !@review

  @header=t_systematic_review_title(@review[:name], :New_search)
  @bb_general_id=BibliographicDatabase[:name=>'generic'][:id]
  @search=Search.new(:user_id=>session['user_id'], :source=>"database_search",:valid=>false, :date_creation=>Date.today, :bibliographic_database_id=>@bb_general_id, :search_type=>"bibliographic_file")
  @usuario=User[session['user_id']]
  haml "searches/search_edit".to_sym, escape_html: false
end


# List of searches for a user
get '/review/:rs_id/searches/user/:user_id' do |rs_id,user_id|
  halt_unless_auth('review_view')
  @review=SystematicReview[rs_id]

  raise Buhos::NoReviewIdError, rs_id if !@review

  @user=User[user_id]
  @header=t_systematic_review_title(@review[:name], t(:searches_user, :user_name=>User[user_id][:name]), false)
  @url_back="/review/#{rs_id}/searches/user/#{user_id}"
  @searches=@review.searches_dataset.where(:user_id=>user_id)
  haml "systematic_reviews/searches".to_sym, escape_html: false
end


# Compare records betweeen searches
get '/review/:rs_id/searches/compare_records' do |rs_id|
  halt_unless_auth('search_view')
  @review=SystematicReview[rs_id]
  raise Buhos::NoReviewIdError, rs_id if !@review
  @cds={}
  @errores=[]
  @searches_id=@review.searches_dataset.map(:id)
  n_searches=@searches_id.length
  @review.searches.each do |search|
    search.records.each do |registro|
      rcd_id=registro[:canonical_document_id]

      if rcd_id
        @cds[rcd_id]||={:searches=>{}}
        @cds[rcd_id][:searches][search[:id]]=true
      else
        errores.push(registro[:id])
      end
    end
  end
  @cds_o=CanonicalDocument.where(:id=>@cds.keys).to_hash(:id)
  @cds_ordered=@cds.sort_by {|key,a|
    #$log.info(@searches_id)
    #$log.info(a)
    base_n=1+a[:searches].length*(2**(n_searches+1))
    #$log.info("Base:#{base_n}")
    sec_n=(0...n_searches).inject(0) {|total,aa|  total+=(a[:searches][@searches_id[aa]].nil? ) ? 0 : 2**aa;total}
    #$log.info("Sec:#{sec_n}")
    base_n+sec_n
  }

  haml "searches/compare_records".to_sym, escape_html: false
end

# @!endgroup
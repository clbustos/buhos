# Buhos
# https://github.com/clbustos/buhos
# Copyright (c) 2016-2023, Claudio Bustos Navarrete
# All rights reserved.
# Licensed BSD 3-Clause License
# See LICENSE file for more information


# @!group references in searches to reviews

# List of canonical documents of a review
get '/review/:id/references' do |id|
  halt_unless_auth('review_view')

  @review=SystematicReview[id]

  raise Buhos::NoReviewIdError, id if !@review

  @pager=get_pager

  @pager.cpp=50
  @pager.order||="cited_by_cd_n__desc"

  @wo_canonical=params['wo_canonical']=='true'
  #$log.info(@wo_canonical)
  #@only_records=params['only_records']=='true'

  @references=@review.bib_references



  # Repetidos doi


  @url="/review/#{id}/references"
  @ref_pre=@references




  if @pager.query
    # Code por pager

    begin
      sp=Buhos::SearchParser.new
      if @pager.query=~/\(.+\)/
        sp.parse(@pager.query)
      else
        sp.parse("text(\"#{@pager.query}\")")
      end
      @ref_pre=@ref_pre.where(Sequel.lit(sp.to_sql))
    rescue Buhos::SearchParser::ParsingError=> e
      add_message(e.message, :error)
    end
    #
  end

  if @wo_canonical
    @ref_pre=@ref_pre.where(:canonical_document_id=>nil)
  end



  @ref_total=@ref_pre.count


  @pager.max_page=(@ref_total/@pager.cpp.to_f).ceil

  #  $log.info(@pager)


  @order_criteria={:cited_by_cd_n=>t(:Citations),
                   :searches_count=>t(:Searches),
                   :text=>t(:Text)}


  @refs=@pager.adjust_page_order(@ref_pre)

  @user=User[session['user_id']]

  cd_ids=@refs.map {|ref|ref[:canonical_document_id]}.find_all{ |cd_id| !cd_id.nil?}
  @cd_hash=CanonicalDocument.where(id:cd_ids).as_hash(:id)

  @asr=AnalysisSystematicReview.new(@review)

  #$log.info(@cd_hash)
  haml %s{systematic_reviews/references}, escape_html: false
end





get "/review/:sr_id/reference/:ref_id" do |sr_id, ref_id|
  halt_unless_auth('review_view')
  @sr_id=sr_id
  @ref_id=ref_id
  @review=SystematicReview[@sr_id]
  raise Buhos::NoReviewIdError, sr_id if !@review
  @ref=Reference[@ref_id]
  raise Buhos::NoReferenceIdError, ref_id if !@ref_id

  # Records



  title(t(:reference_title, ref_title:@ref.text))
  @records=@ref.records_in_sr(@review)

  haml :reference, escape_html: false

end


post '/review/:sr_id/references/actions' do |sr_id|

  halt_unless_auth('review_analyze')

  @ref_ids=params['reference'].keys
  @url_back=params['url_back']
  @user_id=params['user_id']
  @review=SystematicReview[sr_id]
  raise Buhos::NoReviewIdError, sr_id if !@review
  @user=User[@user_id]
  raise Buhos::NoUserIdError, @user_id if !@user
  @refs=Reference.where(:id=>@ref_ids).order(:id)

  add_message(I18n::t(:List_of_references_not_compatible)) unless @refs.count==@ref_ids.length




  action=params['action']
  result=Result.new
  if action=='assigncdcrossref'
    result.add_result(ReferenceProcessor.assign_to_canonical_document(@refs))
  elsif action=='assigncdmanual'
    ref_id=@ref_ids.join(",")
    redirect "/review/#{@review[:id]}/assign_canonical_to_references?references=#{ref_id}"
  elsif action=='removecd'
    result.add_result(Reference.remove_canonicals(@refs))
  else
    raise "#{t(:Action_not_defined)}:#{action}"
  end
  add_result(result)
  redirect back
end

get '/review/:sr_id/assign_canonical_to_references' do |sr_id|
  halt_unless_auth('review_analyze')
  @ref_ids=params['references'].split(",")
  @review=SystematicReview[sr_id]
  @references=Reference.where(:id=>@ref_ids)
  raise Buhos::NoReviewIdError, sr_id if !@review

  haml "systematic_reviews/references_create_canonical_document".to_sym, escape_html: false
end

post '/review/:sr_id/create_canonical_for_references' do |sr_id|
  halt_unless_auth('review_analyze')
  $log.info(params)
  @ref_ids=params['references'].keys()
  @review=SystematicReview[sr_id]
  @references=Reference.where(:id=>@ref_ids)
  raise Buhos::NoReviewIdError, sr_id if !@review
  add_message(I18n::t(:List_of_references_not_compatible)) if @references.count!= @ref_ids.length
  $db.transaction do
    cd_id=CanonicalDocument.insert(:author=>params['author'], :year=>params['year'], :title=>params[:title])
    @references.update(:canonical_document_id=>cd_id)
    add_message("Created canonical document #{cd_id} for #{@ref_ids.length} references")

  end

  redirect "/review/#{sr_id}/references"

end


# @!endgroup

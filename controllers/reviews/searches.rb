# Buhos
# https://github.com/clbustos/buhos
# Copyright (c) 2016-2018, Claudio Bustos Navarrete
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

  $log.info(@user)

  @url_back="/review/#{id}/searches"
  haml "systematic_reviews/searches".to_sym
end


# Form to create a new search
get '/review/:id/search/new' do |id|
  halt_unless_auth('search_edit')

  require 'date'

  @review=SystematicReview[id]
  raise Buhos::NoReviewIdError, id if !@review

  @header=t_systematic_review_title(@review[:name], :New_search)
  @bb_general_id=BibliographicDatabase[:name=>'generic'][:id]
  @search=Search.new(:user_id=>session['user_id'], :source=>"database_search",:valid=>false, :date_creation=>Date.today, :bibliographic_database_id=>@bb_general_id)
  @usuario=User[session['user_id']]
  haml "searches/search_edit".to_sym
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
  haml "systematic_reviews/searches".to_sym
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

  haml "searches/compare_records".to_sym
end

# @!endgroup
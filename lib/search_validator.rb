# Copyright (c) 2016-2024, Claudio Bustos Navarrete
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# * Neither the name of the copyright holder nor the names of its
#   contributors may be used to endorse or promote products derived from
#   this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


# Abstract class to validate  searches
# A search is valid if all records have enough information: title, year, authors and abstract
class SearchValidator

  attr_reader :valid_records_id
  attr_reader :invalid_records_id
  attr_reader :searches_data

  def initialize
    @valid_records_id=[]
    @invalid_records_id=[]
    @searches_data={}

  end
  def valid_records_n
    @valid_records_id.length
  end
  def invalid_records_n
    @invalid_records_id.length
  end
  def valid_records
    Record.where(:id=>@valid_records_id)
  end
  def invalid_records
    Record.where(:id=>@invalid_records_id)
  end

  def searches_n
    Search.where(:systematic_review_id=>@sr.id, :user_id=>@user.id).count
  end
  def searches
    Search.where(:id=>@searches_data.keys)
  end

  def can_docs_query
    raise "Should be implemented"
  end
  def validate
    can_docs=can_docs_query
    #$log.info(can_docs.all)
    @valid_records_id=can_docs.find_all {|v| v[:author].to_s!="" and v[:title].to_s!="" and v[:abstract].to_s!="" and v[:year]!=0}.map {|v| v[:r_id]}
    @invalid_records_id=can_docs.map {|v| v[:r_id]} - @valid_records_id
    update_search(can_docs)
  end

  def valid
    searches_n==0 or (valid_records_n>0 and invalid_records_n==0)
  end

  def update_search(can_docs)
    if can_docs.empty?
      # Don't
      #Search.where(:systematic_review_id=>@sr.id, :user_id=>@user.id).update(:valid=>false)
    else
      can_docs.to_hash_groups(:s_id).each do |key,recs|
        rec_id=recs.map {|v| v[:r_id]}
        valids=@valid_records_id & rec_id
        invalids=@invalid_records_id & rec_id
        @searches_data[key]={
          :n_valid_records=>valids.length,
          :n_invalid_records=>invalids.length,
          :valid=>(valids.length>0 and invalids.length==0)}
        Search[key].update(:valid=> true) if (valids.length>0 and invalids.length==0)
      end
    end
  end



end
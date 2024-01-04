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

#
module Buhos
  # Analysis of a set of tags
  # Criteria could be: systematic review, user, canonical_document, tag_id
  class AnalysisTags
    def initialize
      @canonical_document_id=nil
      @user_id=nil
      @systematic_review_id=nil
      @tag_id=nil
      @canonical_documents_by_tag=nil
    end
    def canonical_document_id(cd_id)
      cd_id=[cd_id] unless cd_id.is_a? Array
      @canonical_document_id=cd_id
    end
    def user_id(user_id)
      user_id=[user_id] unless user_id.is_a? Array

      @user_id=user_id
    end
    def systematic_review_id(sr_id)
      sr_id=[sr_id] unless sr_id.is_a? Array
      @systematic_review_id=sr_id
    end

    def tag_id(tag_id)
      tag_id=[tag_id] unless tag_id.is_a? Array
      @tag_id=tag_id
    end
    # List of tuples of tag_id, text and canonical_document_id
    def tags_in_cds
      @canonical_documents_by_tag||=Tag.join(:tag_in_cds, tag_id: :id).where(Sequel.lit(where_sql)).where(:decision=>TagInCd::DECISION_YES).select(:tag_id, :text, :canonical_document_id)
    end
    def tags_by_canonical_document
      @tags_by_canonical_document||=tags_in_cds.to_hash_groups(:canonical_document_id)
    end

    def canonical_documents_by_tag
      @canonical_documents_by_tag||=tags_in_cds.to_hash_groups(:tag_id)
    end
    def where_sql
      where=["1=1"]
      where.push " canonical_document_id IN (#{@canonical_document_id.join(',')})" if @canonical_document_id
      where.push " user_id IN (#{@user_id.join(',')})" if @user_id
      where.push " systematic_review_id IN (#{@systematic_review_id.join(',')})" if @systematic_review_id
      where.push " tag_id IN (#{@tag_id.join(',')})" if @tag_id
      where.join(' AND ')
    end


    def get_tags_decision_stats
      query="SELECT t.id, t.text, SUM(CASE WHEN decision='yes' THEN 1 ELSE 0 END) as d_yes,
SUM(CASE WHEN decision='no' THEN 1 ELSE 0 END)  as d_no,
COUNT(DISTINCT(canonical_document_id)) as n_documents
FROM tags t INNER JOIN tag_in_cds tic ON t.id=tag_id WHERE #{where_sql}
GROUP BY t.id
HAVING d_yes>0
ORDER BY t.text
"
      $db[query]
    end
  end
end
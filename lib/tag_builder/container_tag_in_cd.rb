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

require_relative "container_tag_mixin"

#
module TagBuilder
  # Container class for Tag assigned to CD
  class ContainerTagInCd
    include ContainerTagMixin
    attr_reader :tag_cd_rs
    def initialize(review,cd)

      @review=review
      @class_tags=[]
      @cd=cd
      # Tags already elected
      @tag_cd_rs=::TagInCd.tags_rs_cd(@review,cd).to_hash_groups(:tag_id)
      # Tag in classes
      #$log.info(@review.t_classes_documents)
      T_Class.classes_documents(@review).each do |clase|
        clase.tags.each do |tag|
          @class_tags.push(tag.id)
          unless @tag_cd_rs.keys.include? tag.id
            @tag_cd_rs[tag.id]=[{:systematic_review_id=>review.id, :canonical_document_id=>cd.id,:tag_id=>tag.id,:text=>tag.text,:user_id=>0,:decision=>nil}]
          end
        end
      end
    end

    def each
      ordered_tags(@tag_cd_rs).each do |v|
        recs=::TagBuilder::TagInCd.new(v[1])
        recs.predeterminado=@class_tags.include? v[0]
        yield recs
      end
    end

  end
end
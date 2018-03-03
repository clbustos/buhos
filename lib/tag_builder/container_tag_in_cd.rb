# Copyright (c) 2016-2018, Claudio Bustos Navarrete
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
module TagBuilder
  class ContainerTagInCd
    include Enumerable
    attr_reader :tag_cd_rs
    def initialize(revision,cd)

      @review=revision
      @cd=cd
      # Tags ya elegidos
      @tag_cd_rs=::TagInCd.tags_rs_cd(revision,cd).to_hash_groups(:tag_id)
      # Ahora, los tags por defecto que falta por elegir
      @predeterminados=[]

      @review.t_clases_documentos.each do |clase|
        clase.tags.each do |tag|
          @predeterminados.push(tag.id)
          unless @tag_cd_rs.keys.include? tag.id
            @tag_cd_rs[tag.id]=[{:systematic_review_id=>revision.id, :canonical_document_id=>cd.id,:tag_id=>tag.id,:text=>tag.text,:user_id=>0,:decision=>nil}]
          end
        end
      end
    end
    def tags_orderados
      @tag_cd_rs.sort {|a,b|
        tag_1=a[1][0]
        tag_2=b[1][0]
        if @predeterminados.include? tag_1[:tag_id] and !@predeterminados.include? tag_2[:tag_id]
          +1
        elsif !@predeterminados.include? tag_1[:tag_id] and @predeterminados.include? tag_2[:tag_id]
          -1
        else
          tag_1[:text]<=>tag_2[:text]
        end
      }
    end
    def each
      tags_orderados.each do |v|
        recs=::TagBuilder::TagInCd.new(v[1])
        recs.predeterminado=@predeterminados.include? v[0]
        yield recs
      end
    end

    end
end
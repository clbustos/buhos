# Copyright (c) 2016-2022, Claudio Bustos Navarrete
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

require_relative 'textual_analysis_mixin'
#
module Buhos
  class DuplicateAnalysis

    attr_reader :canonical_documents
    def initialize(cds)
      begin
        require 'levenshtein-ffi'
      rescue LoadError
        require 'levenshtein'
      end

      @canonical_documents=cds
    end
    # Returns a list of repeated doi
    def by_doi
      canonical_documents.exclude(doi: nil).group_and_count(:doi).having {count.function.* > 1}.all.map {|v| v[:doi]}
    end
    def cd_is_identical(cd1,cd2)
      cd1[:title]==cd2[:title] and cd1[:year]==cd2[:year] and (cd1[:journal].nil? or (cd1[:journal]==cd2[:journal] and cd1[:pages]==cd2[:pages]))
    end

    def cd_dois_arent_different(cd1,cd2)
       !(!cd1[:doi].nil? and !cd2[:doi].nil? and cd1[:doi]!=cd2[:doi])
    end
    def cd_is_very_similar(cd1,cd2)
      t1="#{cd1[:year]} #{cd1[:title]} #{cd1[:authors]} #{cd1[:journal]} #{cd1[:pages]}".gsub(/[^A-Za-z\d\s]/,"").downcase
      t2="#{cd2[:year]} #{cd2[:title]} #{cd2[:authors]} #{cd2[:journal]} #{cd2[:pages]}".gsub(/[^A-Za-z\d\s]/,"").downcase
      if(t1.length>10)
        d=Levenshtein.distance(t1,t2)
        d<5

      else
        false

      end
    end

    # We will use a blocking method based on year.
    # https://www.sciencedirect.com/science/article/pii/S1319157817304512
    # @return array with pairs of duplicates
    def by_metadata
      dups=[]
      v=canonical_documents.to_hash_groups(:year)
      v.each do |r1,r2|
        n=r2.length
        0.upto(n-2) do |i|
          (i+1).upto(n-1) do |j|
            cd1= r2[i]
            cd2= r2[j]
            if (cd_is_identical(cd1,cd2) or cd_is_very_similar(cd1,cd2)) and (cd_dois_arent_different(cd1,cd2))
              dups.push [cd1[:id],cd2[:id]].sort
            end

          end

        end


      end
      dups.sort {|a,b| a[0]<=>b[0]}
    end

  end
end
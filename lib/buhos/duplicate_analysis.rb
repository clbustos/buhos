# Copyright (c) 2016-2025, Claudio Bustos Navarrete
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
    def by_scopus_id
      canonical_documents.exclude(scopus_id: nil).group_and_count(:scopus_id).having {count.function.* > 1}.all.map {|v| v[:scopus_id]}
    end
    def by_wos_id
      canonical_documents.exclude(wos_id: nil).group_and_count(:wos_id).having {count.function.* > 1}.all.map {|v| v[:wos_id]}
    end
    def by_scielo_id
      canonical_documents.exclude(scielo_id: nil).group_and_count(:scielo_id).having {count.function.* > 1}.all.map {|v| v[:scielo_id]}
    end
    def by_pubmed_id
      canonical_documents.exclude(pubmed_id: nil).group_and_count(:pubmed_id).having {count.function.* > 1}.all.map {|v| v[:pubmed_id]}
    end

    def cd_is_identical(cd1,cd2)
      cd1[:title]==cd2[:title] and cd1[:year]==cd2[:year] and (cd1[:journal].nil? or (cd1[:journal]==cd2[:journal] and cd1[:pages]==cd2[:pages]))
    end

    def cd_dois_arent_different(cd1,cd2)
       !(!cd1[:doi].nil? and !cd2[:doi].nil? and cd1[:doi]!=cd2[:doi])
    end
    def cd_is_very_similar(cd1,cd2)
      t1=normalized_metadata_text(cd1)
      t2=normalized_metadata_text(cd2)
      if(t1.length>10)
        d=Levenshtein.distance(t1,t2)
        d<5
        #t1==t2
      else
        false

      end
    end

    def normalized_metadata_text(cd)
      "#{cd[:year]} #{cd[:title]} #{cd[:author]} #{cd[:journal]} #{cd[:pages]}".gsub(/[^A-Za-z\d\s]/,"").downcase
    end

    def metadata_block_keys(cd)
      text=normalized_metadata_text(cd)
      length_block=text.length / 10
      prefixes=[text[0,12]]
      prefixes << text[0,8] if text.length>=8
      prefixes << text[0,4] if text.length>=4
      length_blocks=[length_block-1, length_block, length_block+1].find_all {|block| block>=0}
      prefixes.compact.uniq.product(length_blocks).map {|prefix, block| [cd[:year], block, prefix]}
    end

    def push_unique_pair(dups, seen, cd1_id, cd2_id)
      pair=[cd1_id, cd2_id].sort
      return if seen[pair]

      seen[pair]=true
      dups.push(pair)
    end

    # We will use a blocking method based on year.
    # https://www.sciencedirect.com/science/article/pii/S1319157817304512
    # @return array with pairs of duplicates
    def by_metadata
      dups=[]
      seen={}
      fields=[:id, :year, :title, :author, :journal, :pages, :doi]
      rows=canonical_documents.select(*fields).where(Sequel.~(title: nil)).all

      rows.group_by {|cd| [cd[:year], cd[:title], cd[:journal], cd[:pages]] }.each_value do |group|
        next if group.length<2

        n=group.length
        0.upto(n-2) do |i|
          (i+1).upto(n-1) do |j|
            cd1=group[i]
            cd2=group[j]
            push_unique_pair(dups, seen, cd1[:id], cd2[:id]) if cd_dois_arent_different(cd1, cd2)
          end
        end
      end

      blocks=Hash.new {|hash, key| hash[key]=[]}
      rows.each do |cd|
        metadata_block_keys(cd).each {|key| blocks[key].push(cd)}
      end

      blocks.each_value do |group|
        next if group.length<2

        n=group.length
        0.upto(n-2) do |i|
          (i+1).upto(n-1) do |j|
            cd1=group[i]
            cd2=group[j]
            next if seen[[cd1[:id], cd2[:id]].sort]

            if cd_dois_arent_different(cd1, cd2) and cd_is_very_similar(cd1, cd2)
              push_unique_pair(dups, seen, cd1[:id], cd2[:id])
            end

          end

        end


      end
      dups.sort {|a,b| a[0]<=>b[0]}
    end

    private :normalized_metadata_text
    private :metadata_block_keys
    private :push_unique_pair

  end
end

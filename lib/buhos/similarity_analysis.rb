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


require_relative 'textual_analysis_mixin'
#
module Buhos
  class SimilarAnalysisSr
    include TextualAnalysisMixin
    attr_reader :error
    attr_reader :matrix
    attr_accessor :use_stemmer
    def self.similar_to_cd_in_sr(cd:,sr:)
      sas=SimilarAnalysisSr.new(sr)
      sas.process
      sas.similarity_all_to_one(cd.id)
    end
    def initialize(sr)
      raise I18n::t(:Cant_be_nil) if sr.nil?
      @sr=sr
      @narray_available=true
      @use_stemmer=true
      begin
        require 'narray'
      rescue LoadError
        require 'matrix'
        @narray_available=false
      end
    end

    def process

      require 'tf-idf-similarity'
      require 'unicode_utils'
      require 'lingua/stemmer'

      @cd_w_abstract=@sr.cd_hash.find_all {|v| v[1][:abstract].to_s!=""}
      @corpus=@cd_w_abstract.map {|v| to_tf_idf_similarity v[1][:abstract]}

      @cd_w_abstract_ids=@cd_w_abstract.map {|v|v[0]}

      @model = TfIdfSimilarity::TfIdfModel.new(@corpus, library: (@narray_available ? :narray : :matrix))
      @matrix = @model.similarity_matrix
    end
    def to_tf_idf_similarity(text)
      tokens=tokenize(text, @use_stemmer)
      TfIdfSimilarity::Document.new(text, :tokens => tokens)
    end
    def mean_similarity(cd_ids)
      return nil if cd_ids.length<2

      n=cd_ids.length
      n_sims=0
      total=0
      0.upto(n-2) do |i|
        (i+1).upto(n-1) do |j|
          sim=similarity_two(cd_ids[i],cd_ids[j])
          $log.info(sim)
          if sim
            total+=sim
            n_sims+=1
          end
        end
      end
      (total.to_f/n_sims).round(3)
    end
    def similarity_two(cd_id_1, cd_id_2)
      index_cd_1=@cd_w_abstract_ids.index(cd_id_1)
      index_cd_2=@cd_w_abstract_ids.index(cd_id_2)
      (index_cd_1.nil? or index_cd_2.nil?) ? nil : @matrix[index_cd_1,index_cd_2]
    end
    def similarity_all_to_one(cd_id)
      return nil unless @cd_w_abstract_ids.include? cd_id.to_i
      ids=@cd_w_abstract.find_all{|v| v[0]!=cd_id.to_i}.map {|v| v[0]}
      ids.map {|v| {:id=>v, :similarity=>similarity_two(cd_id.to_i,v)}}.sort_by{|v| -v[:similarity]}
    end
  end
end

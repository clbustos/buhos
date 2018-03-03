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

class NBayes_RS
  attr_reader :nbayes_rtr
  STOPWORDS=%w{the an a with we dont to in that these those from each @ i}

  def initialize(rs)
    require 'nbayes'
    require 'lingua/stemmer'
    @rs=rs
    @nbayes_rtr=nbayes_rtr_calculo
  end

  def get_stemmer(text)
    res=Lingua.stemmer(text.split(/[\s-]+/).map {|vv| vv.downcase.gsub(/[[:punct:]]/, "")}.find_all {|v| !STOPWORDS.include? v})
    res.is_a?(Array) ? res : [res]
  end

  def nbayes_rtr_calculo
    nbayes = NBayes::Base.new
    names = (CanonicalDocument.select(:title, :abstract, :journal, :resolution).join_table(:inner, :resolutions, canonical_document_id: :id).where(:systematic_review_id => @rs.id)).map {|v| {:name => get_stemmer("#{v[:title]} #{v[:abstract]}")+[v[:journal]], :resolution => v[:resolution]}}
    names.each do |n|
      nbayes.train(n[:name], n[:resolution])
    end
    #$log.info(nbayes)
    nbayes
  end

  private :nbayes_rtr_calculo

  # Entrega la clasificación para un cd_id específico
  def cd_resultado(cd_id)
    cd=@rs.cd_hash[cd_id]
    tokens=get_stemmer("#{cd[:title]} #{cd[:abstract]}")+[cd[:journal]]
    res={"yes" => 0, "no" => 0}.merge(nbayes_rtr.classify(tokens))
    #$log.info(res)
    res
  end
end
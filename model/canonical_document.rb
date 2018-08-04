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

class CanonicalDocument < Sequel::Model
  # Corresponde a las references que tienen como canónico a este objeto
  one_to_many :references
  one_to_many :records

  include ReferenceMethods
  # Cada documento genérico realiza references. ¿A quién las hace?

  def references_performed
    ids=$db["SELECT ref.id FROM records r INNER JOIN records_references rr ON r.id=rr.record_id INNER JOIN bib_references ref ON rr.reference_id=ref.id WHERE r.canonical_document_id=?", self[:id]].map(:id)
    Reference.where(:id => ids)
  end

  def update_info_using_record(record)
    fields = [:title, :author, :year, :journal, :volume, :pages, :doi, :journal_abbr, :abstract]
    update_data=fields.inject({}) do |ac,v|
      ac[v]=record.send(v)  unless record.send(v).nil? or (self.send(v).to_s!="")
      ac
    end

    self.update(update_data) unless update_data.keys.length==0


  end
  # Merge canonical documents, according to id
  # TODO: Create a separate class on lib to handle and test this
  def self.merge(pks)
    pks=pks.map {|v| v.to_i}
    pk_id=pks[0]
    pk_otros=pks[1...pks.length]
    resultado=true
    $db.transaction(:rollback => :reraise) do
      columnas=CanonicalDocument.columns
      columnas.delete(:id)

      cds=CanonicalDocument.where(:id => pks)
      fields=columnas.inject({}) {|ac, v| ac[v]=nil; ac}
      cds.each do |cd|
        columnas.find_all {|col| fields[col].nil? or fields[col]==""}.each {|col|
          fields[col]=cd[col]
        }
      end
      CanonicalDocument[pk_id].update(fields)

      [:allocation_cds, :bib_references, :decisions, :file_cds, :resolutions, :tag_in_cds, :records, :canonical_document_authors].each do |table|

        pk=$db.schema(table).find_all {|v|
          v[1][:primary_key]
        }.map {|v| v[0]}
        # On each tuple, I have to detect if exists before
        cache=[]
        $db[table].select(*pk).where(:canonical_document_id=>pks).each do |row|
          fixed_row=row.dup
          fixed_row[:canonical_document_id]=pk_id
          $log.info(cache)
          $log.info(fixed_row)

          if cache.include? fixed_row
            $db[table].where(row).delete
          else
            cache.push(fixed_row)
          end

        end




        $db[table].where(:canonical_document_id=>pks).update(:canonical_document_id=>pk_id)
      end
      # TODO: Should verificate tuples as object described before
      $db[:tag_bw_cds].where(:cd_start=>pks).update(:cd_start=>pk_id)
      $db[:tag_bw_cds].where(:cd_end=>pks).update(:cd_end=>pk_id)

      CanonicalDocument.where(:id => pk_otros).delete
      $db.after_rollback {
        resultado=false
      }
    end
    resultado
  end

  def crossref_integrator
    if self.doi
      CrossrefDoi.reference_integrator_json(self.doi)
    else
      false
    end
  end

  def pubmed_integrator
    if self.pmid
      PubmedRemote.reference_integrator_xml(self.pmid)
    else
      false
    end
  end



  def buscar_references_similares(d=nil,sin_canonico=true)
     begin
      require 'levenshtein-ffi'
    rescue LoadError
      require 'levenshtein'
    end
    d_max=[ref_apa_6.length,self[:title].length].max

    d=d_max if d.nil? or d>d_max
    canonico_sql= sin_canonico ? " OR canonical_document_id IS NULL ": ""

    distancias=Reference.where(Sequel.lit("canonical_document_id!='#{self[:id]}' #{canonico_sql}")).map {|v|
      dis_apa_6=Levenshtein.distance(v[:text],ref_apa_6)
      dis_solo_titulo=Levenshtein.distance(v[:text],self[:title])
      distancia=[dis_apa_6,dis_solo_titulo].min
      {
          :id=>v[:id],
          :canonical_document_id=>v[:canonical_document_id],
          :text=>v[:text],
          :distancia=>distancia
      }

    }
    if !d.nil?
      distancias=distancias.find_all {|v| v[:distancia]<=d}
    end
    distancias.sort {|a,b| a[:distancia]<=>b[:distancia]}
  end

end

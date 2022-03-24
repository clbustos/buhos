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

# Mixin for methods to view and create
# views related to systematic reviews
module SystematicReviewViewsMixin
# Cuenta el número de references hechas a cada reference para la segunda stage
# Se eliminan como destinos aquellos documentos que ya fueron parte de la resolución de la primera stage
  def count_references_rtr_tn
    "sr_#{self[:id]}_references_between_cd_rtr_n"
  end

  def count_references_rtr
    references_bw_canonical
    resolutions_title_abstract # Verifico que exista la tabla de resolutions
    view_name = count_references_rtr_tn
    if @count_references_rtr_table_exists.nil?
        @count_references_rtr_table_exists=true
      if !$db.table_exists?(view_name)
        $db.run("CREATE VIEW #{view_name} AS SELECT cd_end , COUNT(DISTINCT(cd_start)) as n_references_rtr  FROM resolutions r INNER JOIN #{references_bw_canonical_tn} rec ON r.canonical_document_id=rec.cd_start LEFT JOIN #{resolutions_title_abstract_tn} as r2 ON r2.canonical_document_id=rec.cd_end WHERE r.systematic_review_id=#{self[:id]} and r.stage='screening_title_abstract' and r.resolution='yes' and r2.canonical_document_id IS NULL GROUP BY cd_end")
      end
    end
    $db[view_name.to_sym]

  end


  def resolutions_full_text
    view_name = resolutions_full_text_tn
    if @resolutions_full_text_tn_exists.nil?
      @resolutions_full_text_tn_exists=true
      if !$db.table_exists?(view_name)
        $db.run("CREATE VIEW #{view_name} AS SELECT * FROM resolutions  where systematic_review_id=#{self[:id]} and stage='review_full_text'")
      end

    end
    $db[view_name.to_sym]
  end

  def resolutions_full_text_tn
    "sr_#{self[:id]}_resolutions_full_text"
  end

  def resolutions_references
    view_name = resolutions_references_tn
    if @resolutions_references_tn_exists.nil?
      @resolutions_references_tn_exists=true
      if !$db.table_exists?(view_name)
        $db.run("CREATE VIEW #{view_name} AS SELECT * FROM resolutions  where systematic_review_id=#{self[:id]} and stage='screening_references'")
      end

    end
    $db[view_name.to_sym]
  end

  def resolutions_references_tn
    "sr_#{self[:id]}_resolutions_references"
  end

  def resolutions_title_abstract
    view_name = resolutions_title_abstract_tn
    if @resolutions_title_abstract_tn_exists.nil?
      @resolutions_title_abstract_tn_exists=true
      if !$db.table_exists?(view_name)
        $db.run("CREATE VIEW #{view_name} AS SELECT * FROM resolutions  where systematic_review_id=#{self[:id]} and stage='screening_title_abstract'")
      end
    end
    $db[view_name.to_sym]
  end

  def resolutions_title_abstract_tn
    "sr_#{self[:id]}_resolutions_sta"
  end

  def count_references_bw_canonical
    view_name = count_references_bw_canonical_tn
    if @count_references_bw_canonical_tn_exists.nil?
      @count_references_bw_canonical_tn_exists=true
      if !$db.table_exists?(view_name)
        $db.run("CREATE VIEW #{view_name} AS SELECT cd.canonical_document_id as cd_id, COUNT(DISTINCT(r1.cd_end)) as n_total_references_made, COUNT(DISTINCT(r2.cd_start)) as n_total_references_in FROM #{cd_id_table_tn} cd LEFT JOIN #{references_bw_canonical_tn} r1 ON cd.canonical_document_id=r1.cd_start LEFT JOIN #{references_bw_canonical_tn} r2 ON cd.canonical_document_id=r2.cd_end GROUP BY cd.canonical_document_id")
      end
    end
    $db[view_name.to_sym]
  end

  # THis is

  def count_references_bw_canonical_tn
    "sr_#{self[:id]}_references_between_cd_n"
  end


  def references_bw_canonical_tn
    "sr_#{self[:id]}_references_between_cd"

  end

  # Entrega dataset con las references que existen entre
# canonicos.
# Los campos son cd_start y cd_end
  def references_bw_canonical
    view_name = references_bw_canonical_tn
    if @references_bw_canonical_tn_exists.nil?
      @references_bw_canonical_tn_exists=true
      if !$db.table_exists?(view_name)
        $db.run("CREATE VIEW #{view_name} AS SELECT r.canonical_document_id as cd_start, ref.canonical_document_id as cd_end FROM records r INNER JOIN records_searches br ON r.id=br.record_id INNER JOIN searches b ON br.search_id=b.id  INNER JOIN  records_references rr ON rr.record_id=r.id INNER JOIN bib_references ref ON ref.id=rr.reference_id   WHERE systematic_review_id='#{self[:id]}' AND ref.canonical_document_id IS NOT NULL AND b.valid=1 GROUP BY cd_start, cd_end")
      end
    end
    $db[view_name.to_sym]
  end

  def bib_references
    view_name = bib_references_tn
    if @bib_references_tn_exists.nil?
      @bib_references_tn_exists=true
      if !$db.table_exists?(view_name)
        $db.run("CREATE VIEW #{view_name} AS SELECT refs.id, refs.text, refs.doi, refs.canonical_document_id,
COUNT(DISTINCT(r.canonical_document_id)) as cited_by_cd_n,
COUNT(DISTINCT(s.id)) as searches_count
FROM bib_references refs
INNER JOIN records_references rr ON refs.id = rr.reference_id
INNER JOIN records r ON rr.record_id=r.id
INNER JOIN records_searches br ON r.id=br.record_id
INNER JOIN searches s ON br.search_id=s.id WHERE s.systematic_review_id=#{self[:id]} GROUP BY refs.id")
      end
    end
    $db[view_name.to_sym]
  end
  def bib_references_tn
    "sr_bib_references_#{self[:id]}"
  end
# Entrega todos los id pertinentes para la revision sistematica
  def cd_id_table
    view_name = cd_id_table_tn
    if @cd_id_table_tn_exists.nil?
      @cd_id_table_tn_exists=true
      if !$db.table_exists?(view_name)
        $db.run("CREATE VIEW #{view_name} AS SELECT DISTINCT(r.canonical_document_id) FROM records r INNER JOIN records_searches br ON r.id=br.record_id INNER JOIN searches b ON br.search_id=b.id WHERE b.systematic_review_id=#{self[:id]} AND b.valid=1

        UNION

        SELECT DISTINCT r.canonical_document_id FROM searches b INNER JOIN records_searches br ON b.id=br.search_id INNER JOIN records_references rr ON br.record_id=rr.record_id INNER JOIN bib_references r ON rr.reference_id=r.id  WHERE b.systematic_review_id=#{self[:id]} and r.canonical_document_id IS NOT NULL and b.valid=1 GROUP BY r.canonical_document_id")
      end
    end
    $db[view_name.to_sym]
  end

# Vistas especiales
  def cd_id_table_tn
    "rs_cd_id_#{self[:id]}"
  end
end

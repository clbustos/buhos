# Buhos
# https://github.com/clbustos/buhos
# Copyright (c) 2016-2025, Claudio Bustos Navarrete
# All rights reserved.
# Licensed BSD 3-Clause License
# See LICENSE file for more information



# @!group Import and export decisions

post '/review/:sr_id/canonical_documents/import_excel_reviewed' do |sr_id|
  halt_unless_auth_any('review_admin')
  #$log.info(params)
  @review=SystematicReview[sr_id]
  raise Buhos::NoReviewIdError, sr_id if !@review

  cds_list=@review.cd_all_id
  cd_to_update=params["canonical_document"]
  if cd_to_update.nil?
    add_message("No document to update", :warning)
    redirect url("review/#{sr_id}/canonical_documents/import_export")
  end
  i=0
  $db.transaction(:rollback=>:reraise) do
      cd_to_update.each do |key,vals|

        if cds_list.map {|v| v.to_s}.include? key
          if vals.key?("updated") and vals['updated']=="on"
            hash_to_update=vals.each_with_object({}) {|v,acc|
              acc[v[0].to_sym]=v[1].to_s.strip if v[0]!="updated"
            }
            CanonicalDocument[key].update(hash_to_update)
            i+=1
          end
        end

      end

    end
    add_message(t("Number of canonical documents updated:#{i}"))
    redirect url("review/#{sr_id}/canonical_documents/import_export")
end

# TODO: The system doesn't check proper authorization. Use with care
post '/review/:sr_id/canonical_documents/import_excel' do |sr_id|
  halt_unless_auth_any('review_admin')
  #$log.info(params)
  @review=SystematicReview[sr_id]
  cds=@review.cd_all_id
  #$log.info(cds)
  raise Buhos::NoReviewIdError, sr_id if !@review
  archivo=params.delete("file")

  require 'simple_xlsx_reader'
  SimpleXlsxReader.configuration.auto_slurp = true
  #$log.info(archivo)
  doc = SimpleXlsxReader.open(archivo["tempfile"])

  valid_headers=%w{title	year	author	journal	volume	pages	doi	wos_id	scielo_id	scopus_id	abstract}
  rows=doc.sheets.first.rows
  cd_ids_a_revisar=[]
  cd_dato_nuevo=rows.each(headers: true).with_object({}) do |row, acc|
    if cds.include? row['canonical_document_id'].to_i
      cd_ids_a_revisar.append(row['canonical_document_id'].to_i)
      datos=valid_headers.inject({}) {|acc,v|
        acc[v]=row[v] if row.key?(v)
        acc
      }
      acc[row["canonical_document_id"]] = datos
    end
  end



  canonical_base=CanonicalDocument.where(:id=>cd_ids_a_revisar).as_hash(:id)

  @updated_data_per_cd=cd_dato_nuevo.each_with_object({}) {|v,acc|
    cd_id, data_cd=v
    datos=data_cd.each_with_object({}) {|v2,acc2|
      key_v, data_v=v2
      if ["year", "volume"].include? key_v and data_v.is_a? Numeric
        data_v=data_v.to_i
      end
      acc2[key_v]=data_v if data_v.to_s!=canonical_base[cd_id.to_i][key_v.to_sym].to_s
    }
    if datos.length>0

      acc[cd_id.to_i]=datos
      acc[cd_id.to_i]['original_title']=canonical_base[cd_id.to_i][:title]
    end

  }
  haml "canonical_documents/import_review".to_sym, escape_html: false

end


# @!endgroup
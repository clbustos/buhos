# Buhos
# https://github.com/clbustos/buhos
# Copyright (c) 2016-2022, Claudio Bustos Navarrete
# All rights reserved.
# Licensed BSD 3-Clause License
# See LICENSE file for more information



# @!group Import and export decisions

# TODO: The system doesn't check proper authorization. Use with care
post '/review/import_decisions_excel' do
  halt_unless_auth_any('review_admin', 'review_admin_view')
  $log.info(params)
  sr_id=params['systematic_review_id']
  @review=SystematicReview[sr_id]


  cds=@review.cd_all_id
  #$log.info(cds)

  raise Buhos::NoReviewIdError, sr_id if !@review
  archivo=params.delete("file")

  require 'simple_xlsx_reader'
  #$log.info(archivo)
  doc = SimpleXlsxReader.open(archivo["tempfile"])


  sheet=doc.sheets.first
  header=sheet.headers
  sr_idx=header.find_index("systematic_review_id")
  cd_idx=header.find_index("canonical_document_id")
  user_idx=header.find_index("user_id")
  stage_idx=header.find_index("stage")
  decision_idx=header.find_index("decision")
  commentary_idx=header.find_index("commentary")


  n_update=0
  n_insert=0
  n_errors=0
  $db.transaction(:rollback => :always) do
    sheet.data.each do |row|
      sr_id      = row[sr_idx].to_i
      cd_id      = row[cd_idx].to_i
      user_id    = row[user_idx].to_i
      stage      = row[stage_idx].to_s
      decision   = (row[decision_idx].nil? or row[decision_idx].strip=="") ? Decision::NO_DECISION : row[decision_idx].strip.downcase
      commentary = row[commentary_idx]

      if Decision::N_EST.keys().include? decision and cds.include? cd_id

        previous_dec=Decision[:systematic_review_id=>sr_id, :user_id=>user_id, :canonical_document_id=>cd_id, :stage=>stage]

        if previous_dec
          n_update+=1
          previous_dec.update(:decision=>decision, :commentary=>commentary)
        else
          n_insert+=1
          Decision.insert(:systematic_review_id=>sr_id, :user_id=>user_id, :canonical_document_id=>cd_id, :stage=>stage,
                          :decision=>decision, :commentary=>commentary)
        end
      end
    end
  end


  add_message(t("systematic_review_page.import_decisions_excel", n_update:n_update, n_insert: n_insert))
  redirect back

end


# @!endgroup
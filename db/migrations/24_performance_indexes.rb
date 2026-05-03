Sequel.migration do
  change do
    alter_table(:records_searches) do
      add_index [:record_id], :name=>:records_searches_record_id_index
    end

    alter_table(:records_references) do
      add_index [:record_id], :name=>:records_references_record_id_index
    end

    alter_table(:searches) do
      add_index [:systematic_review_id, :valid], :name=>:searches_sr_valid_index
    end

    alter_table(:decisions) do
      add_index [:systematic_review_id, :stage, :canonical_document_id], :name=>:decisions_sr_stage_cd_index
      add_index [:systematic_review_id, :stage, :user_id, :canonical_document_id], :name=>:decisions_sr_stage_user_cd_index
    end

    alter_table(:resolutions) do
      add_index [:systematic_review_id, :stage, :resolution, :canonical_document_id], :name=>:resolutions_sr_stage_resolution_cd_index
    end

    alter_table(:allocation_cds) do
      add_index [:systematic_review_id, :stage, :canonical_document_id], :name=>:allocation_cds_sr_stage_cd_index
      add_index [:systematic_review_id, :stage, :user_id, :canonical_document_id], :name=>:allocation_cds_sr_stage_user_cd_index
    end

    alter_table(:message_srs) do
      add_index [:systematic_review_id], :name=>:message_srs_sr_index
    end
  end
end

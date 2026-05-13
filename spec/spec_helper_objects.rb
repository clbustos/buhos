module SpecHelperObjects
  # Helpers to build the minimal dataset used by stage-related specs.
  def create_stage_dataset
    create_sr
    create_search(id:[1])
    create_stage_canonical_documents
    create_stage_records
    create_stage_references
    create_stage_allocations
    create_stage_decisions
    create_stage_resolutions
    create_stage_tags
  end

  def create_stage_canonical_documents
    1.upto(8) do |id|
      title = id == 4 ? 'A Tool to Help Large SLURP reviews' : "Pager document #{id}"
      CanonicalDocument.insert(:id=>id, :title=>title, :year=>2020)
    end
  end

  def create_stage_records
    create_record(id:[1,2,3,4,5],
                  cd_id:[1,2,3,4,5],
                  search_id:[[1],[1],[1],[1],[1]])
  end

  def create_stage_references
    create_references(
      texts:[
        'record 1 cites document 6',
        'record 1 cites document 7',
        'record 1 cites document 8',
        'record 2 cites document 6',
        'record 2 cites document 7',
        'record 2 cites document 8'
      ],
      cd_id:[6,7,8,6,7,8],
      record_id:[1,1,1,2,2,2]
    )
  end

  def create_stage_allocations
    1.upto(5) do |cd_id|
      AllocationCd.insert(:systematic_review_id=>1, :canonical_document_id=>cd_id,
                          :user_id=>1, :stage=>'screening_title_abstract')
    end

    [6,7,8].each do |cd_id|
      AllocationCd.insert(:systematic_review_id=>1, :canonical_document_id=>cd_id,
                          :user_id=>1, :stage=>'screening_references')
    end

    [1,2,6,7].each do |cd_id|
      AllocationCd.insert(:systematic_review_id=>1, :canonical_document_id=>cd_id,
                          :user_id=>1, :stage=>'review_full_text')
    end

    [1,6].each do |cd_id|
      AllocationCd.insert(:systematic_review_id=>1, :canonical_document_id=>cd_id,
                          :user_id=>1, :stage=>'extract_information')
    end
  end

  def create_stage_decisions
    [1,2,3].each do |cd_id|
      Decision.insert(:systematic_review_id=>1, :canonical_document_id=>cd_id,
                      :user_id=>1, :stage=>'screening_title_abstract',
                      :decision=>'yes')
    end

    Decision.insert(:systematic_review_id=>1, :canonical_document_id=>6,
                    :user_id=>1, :stage=>'screening_references',
                    :decision=>'yes')

    [1,2,6].each do |cd_id|
      Decision.insert(:systematic_review_id=>1, :canonical_document_id=>cd_id,
                      :user_id=>1, :stage=>'review_full_text',
                      :decision=>'yes')
    end
  end

  def create_stage_resolutions
    [1,2].each do |cd_id|
      Resolution.insert(:systematic_review_id=>1, :canonical_document_id=>cd_id,
                        :user_id=>1, :stage=>'screening_title_abstract',
                        :resolution=>'yes')
    end

    [6,7].each do |cd_id|
      Resolution.insert(:systematic_review_id=>1, :canonical_document_id=>cd_id,
                        :user_id=>1, :stage=>'screening_references',
                        :resolution=>'yes')
    end

    [1,6].each do |cd_id|
      Resolution.insert(:systematic_review_id=>1, :canonical_document_id=>cd_id,
                        :user_id=>1, :stage=>'review_full_text',
                        :resolution=>'yes')
    end
  end

  def create_stage_tags
    Tag.insert(:id=>1, :text=>'tools')
    [1,2,6].each do |cd_id|
      TagInCd.insert(:tag_id=>1, :canonical_document_id=>cd_id, :user_id=>1,
                     :systematic_review_id=>1, :decision=>'yes')
    end
  end
end

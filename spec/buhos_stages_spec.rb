require_relative 'spec_helper'

describe Buhos::Stages do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    configure_empty_database
    create_stage_dataset

    Resolution.where(systematic_review_id:1).delete

    [1, 2].each do |cd_id|
      Resolution.insert(systematic_review_id:1,
                        canonical_document_id:cd_id,
                        user_id:1,
                        stage:Buhos::Stages::STAGE_SCREENING_TITLE_ABSTRACT.to_s,
                        resolution:Resolution::RESOLUTION_ACCEPT)
    end

    Resolution.insert(systematic_review_id:1,
                      canonical_document_id:6,
                      user_id:1,
                      stage:Buhos::Stages::STAGE_SCREENING_REFERENCES.to_s,
                      resolution:Resolution::RESOLUTION_ACCEPT)

    Resolution.insert(systematic_review_id:1,
                      canonical_document_id:1,
                      user_id:1,
                      stage:Buhos::Stages::STAGE_REVIEW_FULL_TEXT.to_s,
                      resolution:Resolution::RESOLUTION_ACCEPT)
  end

  let(:review) { SystematicReview[1] }

  it 'moves title/abstract and reference accepted documents to full-text review' do
    expect(review.cd_id_by_stage(Buhos::Stages::STAGE_REVIEW_FULL_TEXT).sort).
      to eq([1, 2, 6])
  end

  it 'moves only full-text accepted documents to information extraction' do
    expect(review.cd_id_by_stage(Buhos::Stages::STAGE_REVIEW_EXTRACT_INFORMATION).sort).
      to eq([1])
  end

  after(:all) do
    close_sqlite
  end
end

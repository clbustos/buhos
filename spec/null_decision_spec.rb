require_relative 'spec_helper'

describe 'A NULL decision is equivalent to a missing decision' do
  include RSpecMixin

  before do
    configure_empty_database
    create_stage_dataset
    @review=SystematicReview[1]
    @stage='screening_title_abstract'
    # Document 4 has one allocation and no decision in the stage dataset.
    @cd_id=4
  end

  def insert_null_decision
    Decision.insert(systematic_review_id:@review.id, canonical_document_id:@cd_id,
                    user_id:1, stage:@stage, decision:nil)
  end

  it 'preserves the user pending decision and totals' do
    missing=AnalysisUserDecision.new(@review.id, 1, @stage)
    insert_null_decision
    with_null=AnalysisUserDecision.new(@review.id, 1, @stage)

    expect(with_null.decision_cd_id(@cd_id)).to eq(Decision::NO_DECISION)
    expect(with_null.decision_by_cd).to eq(missing.decision_by_cd)
    expect(with_null.total_decisions).to eq(missing.total_decisions)
  end

  it 'preserves the stage decision counts with one pending reviewer' do
    missing=Analysis_SR_Stage.new(@review, @stage).decisions_by_cd.fetch(@cd_id)
    expect(missing).to eq('yes'=>0, 'no'=>0, 'undecided'=>0, 'ND'=>1)
    insert_null_decision

    expect(Analysis_SR_Stage.new(@review, @stage).decisions_by_cd.fetch(@cd_id)).to eq(missing)
  end

  it 'keeps the document in the ND_1 pattern used by the view route' do
    pattern='yes_0__no_0__undecided_0__ND_1'
    missing=AnalysisSystematicReview.new(@review)
    ids=missing.cd_from_pattern(@stage, missing.pattern_from_s(pattern))
    expect(ids).to include(@cd_id)
    insert_null_decision
    with_null=AnalysisSystematicReview.new(@review)

    expect(with_null.cd_from_pattern(@stage, with_null.pattern_from_s(pattern))).to eq(ids)
  end

  it 'does not mark a document as screened just because a NULL decision exists' do
    missing=Analysis_SR_Stage.new(@review, @stage).cd_screened_id
    expect(missing).not_to include(@cd_id)
    insert_null_decision

    expect(Analysis_SR_Stage.new(@review, @stage).cd_screened_id).to match_array(missing)
  end
end

require_relative 'spec_helper'

describe 'Assigning reviewers from a decision pattern' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    configure_empty_database
    create_stage_dataset
    User.insert(id:90, login:'outside', name:'Outside reviewer', role_id:'analyst', password:'unused', active:true)
    User.insert(id:91, login:'inactive', name:'Inactive reviewer', role_id:'analyst', password:'unused', active:false)
    GroupsUser.insert(group_id:1, user_id:91)
  end

  before do
    login_admin
  end

  def allocation(stage, cd_id, user_id)
    AllocationCd.where(systematic_review_id:1, stage:stage, canonical_document_id:cd_id, user_id:user_id)
  end

  %w[screening_title_abstract screening_references review_full_text extract_information].each do |stage|
    it "offers eligible reviewers and adds only the chosen allocation for #{stage}" do
      review=SystematicReview[1]
      cd_id=review.cd_id_by_stage(stage).first
      ars=AnalysisSystematicReview.new(review)
      pattern=ars.pattern_id(ars.decisions_by_cd(stage)[cd_id])
      path="/review/1/stage/#{stage}/pattern/#{pattern}"
      get "#{path}/view"
      expect(last_response).to be_ok
      html=Nokogiri::HTML(last_response.body)
      form=html.at_css("form.assign-pattern-reviewer:has(input[value='#{cd_id}'])")
      expect(form).not_to be_nil
      options=form.css('option').map {|option| option['value'].to_i}
      expect(options).to include(2)
      expect(options).not_to include(1, 90, 91)
      before_count=AllocationCd.count
      2.times do
        post "#{path}/assign", canonical_document_id:cd_id, assigned_user_id:2
        expect(last_response).to be_redirect
      end
      expect(allocation(stage, cd_id, 2).count).to eq(1)
      expect(AllocationCd.count).to eq(before_count+1)
      follow_redirect!
      expect(last_response).to be_ok
      allocation(stage, cd_id, 2).delete
    end
  end

  it 'rejects users outside the group, inactive users and documents outside the stage' do
    path='/review/1/stage/screening_title_abstract/pattern/yes_1__no_0__undecided_0__ND_0/assign'
    previous=AllocationCd.count
    [90, 91, 999].each do |user_id|
      post path, canonical_document_id:1, assigned_user_id:user_id
      expect(last_response.status).to eq(400)
    end
    post path, canonical_document_id:999, assigned_user_id:2
    expect(last_response.status).to eq(400)
    expect(AllocationCd.count).to eq(previous)
  end

  it 'requires permission to administer reviews' do
    login_analyst
    post '/review/1/stage/screening_title_abstract/pattern/yes_1__no_0__undecided_0__ND_0/assign', canonical_document_id:1, assigned_user_id:2
    expect(last_response.status).to eq(403)
  end

  after(:all) do
    close_sqlite
  end
end

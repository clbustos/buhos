require 'spec_helper'

describe 'Create a new systematic review using the web interface' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    @temp=configure_empty_database
    User.insert(:id=>10, :login=>"user_without_group",
                :password=>Digest::SHA1.hexdigest("user_without_group"),
                :role_id=>"administrator",:active => 1)
  end

  context 'when admin user access to /review/new' do
    before(:context) do
      login_admin
      get "/review/new"
    end
    it "should response be ok" do
      expect(last_response).to be_ok
    end
    it "should show correct title" do
      expect(last_response.body).to include(I18n::t(:Systematic_review_new))
    end

  end

  context 'when analyst user without permission access to /review/new' do
    before(:context) do
      login_analyst
      get "/review/new"
    end
    it "should status code will be not authorized" do
      expect(last_response.status).to eq(403)
    end

  end

  context 'when user with permission but without group access to /review/new' do
    before(:context) do
      post '/login', :user=>"user_without_group", :password=>"user_without_group"
      get "/review/new"
    end
    it 'defaults to a new group outside the tabs and makes the creator its only member and administrator' do
      expect(last_response).to be_ok
      html=Nokogiri::HTML(last_response.body)
      expect(html.at_css('input[name="group_mode"][value="new"][checked]')).not_to be_nil
      expect(html.at_css('.tab-content select[name="group_id"]')).to be_nil

      post '/review/update', review_id:'', name:'Review with its own group'
      expect(last_response).to be_redirect
      review=SystematicReview[name:'Review with its own group']
      expect(review.group.group_administrator).to eq(10)
      expect(review.sr_administrator).to eq(10)
      expect(review.group.users.map(&:id)).to eq([10])
    end
  end

  it 'limits editors without group administration permission to their own groups and the default administrator' do
    Role['analyst'].add_auth_to(Authorization['review_edit'])
    login_analyst
    get '/review/new'
    expect(last_response).to be_ok
    html=Nokogiri::HTML(last_response.body)
    expect(html.css('#group_id_select option').map {|option| option['value']}).to eq(['1'])
    expect(html.at_css('#group_administrator_select')).to be_nil

    post '/review/update', review_id:'', name:'Outside group', group_mode:'existing', group_id:2
    expect(last_response.status).to eq(403)
    post '/review/update', review_id:'', name:'Changed administrator', group_mode:'existing', group_id:1, sr_administrator:2
    expect(last_response.status).to eq(403)
    post '/review/update', review_id:'', name:'Existing group', group_mode:'existing', group_id:1
    expect(last_response).to be_redirect
    review=SystematicReview[name:'Existing group']
    expect([review.group_id, review.sr_administrator]).to eq([1, 1])
    get "/review/#{review.id}/edit"
    expect(last_response).to be_ok
    post '/review/update', review_id:review.id, group_id:2
    expect(last_response.status).to eq(403)
  ensure
    AuthorizationsRole.where(authorization_id:'review_edit', role_id:'analyst').delete
  end

  it 'lets group administrators select an existing group and any of its members as review administrator' do
    post '/login', user:'user_without_group', password:'user_without_group'
    get '/review/new'
    expect(last_response).to be_ok
    html=Nokogiri::HTML(last_response.body)
    group=html.at_css('#group_id_select option[value="1"]')
    expect(JSON.parse(group['data-members']).map {|member| member.fetch('id')}).to match_array([1, 2])

    post '/review/update', review_id:'', name:'Wrong administrator', group_mode:'existing', group_id:2, sr_administrator:2
    expect(last_response.status).to eq(422)

    post '/review/update', review_id:'', name:'Chosen administrator', group_mode:'existing', group_id:1, sr_administrator:2
    expect(last_response).to be_redirect
    review=SystematicReview[name:'Chosen administrator']
    expect([review.group_id, review.sr_administrator]).to eq([1, 2])

    post '/review/update', review_id:review.id, group_id:2
    expect(last_response).to be_redirect
    expect([review.refresh.group_id, review.sr_administrator]).to eq([2, 1])
  end

  it 'requires all assigned reviewers and people with decisions or resolutions to belong to the destination group' do
    login_admin
    review=SystematicReview.create(name:'Review with participants', group_id:1, sr_administrator:1, date_creation:Date.today)
    unrelated_review=SystematicReview.create(name:'Unrelated review', group_id:2, sr_administrator:1)
    document=CanonicalDocument.create(title:'Document with participants', year:2025)
    unrelated_user=User.create(login:'unrelated_reviewer', role_id:'analyst', password:Digest::SHA1.hexdigest('unused'))
    destination=Group.create(name:'Destination', group_administrator:1)
    destination.add_user(User[1])
    participants={Decision=>2, Resolution=>3, AllocationCd=>10}
    scope={systematic_review_id:review.id, canonical_document_id:document.id, stage:'screening_title_abstract'}
    Decision.insert(scope.merge(user_id:2, decision:'yes'))
    Resolution.insert(scope.merge(user_id:3, resolution:'yes'))
    AllocationCd.insert(scope.merge(user_id:10))
    Decision.insert(scope.merge(systematic_review_id:unrelated_review.id, user_id:unrelated_user.id, decision:'yes'))

    get "/review/#{review.id}/edit"
    expect(last_response).to be_ok
    html=Nokogiri::HTML(last_response.body)
    expect(html.css('#group_id_select option').map {|option| option['value']}).to eq(['1'])

    participants.each_value do |user_id|
      post '/review/update', review_id:review.id, group_id:destination.id
      expect(last_response.status).to eq(422)
      expect(review.refresh.group_id).to eq(1)
      destination.add_user(User[user_id])
    end

    post '/review/update', review_id:review.id, group_id:destination.id
    expect(last_response).to be_redirect
    expect(review.refresh.group_id).to eq(destination.id)
  end
end

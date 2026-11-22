require_relative 'spec_helper'

describe 'Independent researcher permissions' do
  include RSpecMixin

  before do
    configure_empty_database
    @researcher=User.create(login: 'independent', name: 'Researcher', email: 'independent@example.com',
                            password: Digest::SHA1.hexdigest('secret'), role_id: 'independent_researcher')
    SystematicReview.insert(id: 99, name: 'Private review', group_id: 2, sr_administrator: 1)
    @other_review=SystematicReview[99]
    sign_in(@researcher)
  end

  def sign_in(user)
    clear_cookies
    post '/login', user: user.login, password: 'secret'
  end

  def create_review(name, **group_options)
    post '/review/update', {review_id: '', name: name, date_creation: '2026-01-01'}.merge(group_options)
    expect(last_response).to be_redirect
    SystematicReview[name: name]
  end

  it 'creates and administers its own review and only lists its own groups and reviews' do
    get '/review/new'
    expect(last_response).to be_ok
    review=create_review('Independent review')
    expect(review.sr_administrator).to eq(@researcher.id)
    expect(review.group.users.map(&:id)).to eq([@researcher.id])

    get "/review/#{review.id}/administration_stages"
    expect(last_response).to be_ok
    get "/review/#{review.id}/invitations", count: 1
    expect(last_response).to be_ok
    get '/my_groups'
    expect(last_response.body).to include(review.group.name)
    expect(last_response.body).not_to include(@other_review.group.name)
    get '/reviews', show_only_user: 'no'
    expect(last_response.body).to include(review.name)
    expect(last_response.body).not_to include(@other_review.name)

    ["/review/#{@other_review.id}", "/review/#{@other_review.id}/canonical_documents",
     "/review/#{@other_review.id}/invitations", '/group/2', '/group/2/datos.json', '/admin/groups',
     '/user/1', '/user/1/messages'].each do |path|
      get path
      expect(last_response.status).to eq(403), path
    end
    post '/review/update', review_id: @other_review.id, name: 'Unauthorized'
    expect(last_response.status).to eq(403)
  end

  it 'administers a review it created in a shared group and can separate it before inviting' do
    Group[1].add_user(@researcher)
    review=create_review('Shared research', group_mode: 'existing', group_id: 1)
    expect(review.sr_administrator).to eq(@researcher.id)
    expect(review.group.group_administrator).to eq(1)

    get "/review/#{review.id}/edit"
    expect(last_response).to be_ok
    expect(Nokogiri::HTML(last_response.body).at_css('input[name=group_mode][value=new]')).not_to be_nil
    post '/review/update', review_id: review.id, group_mode: 'new'
    expect(last_response).to be_redirect
    expect(review.refresh.group.users.map(&:id)).to eq([@researcher.id])
  end

  it 'lets the owner work on documents in the review and blocks documents outside it' do
    create_stage_dataset
    review=SystematicReview[1]
    review.group.add_user(@researcher)
    review.update(sr_administrator: @researcher.id)
    document=CanonicalDocument.create(title: 'Outside document', year: 2026)
    resolution_path="/resolution/review/#{review.id}/canonical_document"
    stage='screening_title_abstract'

    post "#{resolution_path}/1/stage/#{stage}/resolution", resolution: 'yes', user_id: 1
    expect(last_response).to be_ok
    expect(Resolution[systematic_review_id: review.id, canonical_document_id: 1, stage: stage].user_id).to eq(@researcher.id)
    post "#{resolution_path}/#{document.id}/stage/#{stage}/resolution", resolution: 'yes'
    expect(last_response.status).to eq(404)

    get "/review/#{review.id}/canonical_document/#{document.id}"
    expect(last_response.status).to eq(404)
  end

  it 'gives a new invitee access to the shared group while keeping review administration with the owner' do
    include_group=create_review('First review').group_id
    first=SystematicReview[name: 'First review']
    second=create_review('Second review', group_mode: 'existing', group_id: include_group)
    Mail::TestMailer.deliveries.clear
    post "/review/#{first.id}/invitations", names: ['Collaborator'], emails: ['collaborator@example.com']
    expect(last_response).to be_redirect
    expect(Mail::TestMailer.deliveries.size).to eq(1)
    invitation=Invitation[email: 'collaborator@example.com']

    clear_cookies
    post "/invitation/#{invitation.token}/decision", decision: 'accepted'
    post "/invitation/#{invitation.token}/register", login: 'collaborator', password: 'secret', repeat_password: 'secret'
    expect(last_response).to be_redirect
    collaborator=invitation.refresh.user
    expect(collaborator.role_id).to eq('review_collaborator')
    sign_in(collaborator)
    [first, second].each do |review|
      get "/review/#{review.id}/dashboard"
      expect(last_response).to be_ok
      get "/review/#{review.id}/invitations"
      expect(last_response.status).to eq(403)
    end
    get "/review/#{@other_review.id}"
    expect(last_response.status).to eq(403)
  end
end

require_relative 'spec_helper'
require 'mail'

describe 'Self-registration' do
  include RSpecMixin

  before do
    configure_empty_database
    Buhos::Configuration.set('SELF_REGISTRATION', 'true')
    Mail::TestMailer.deliveries.clear
  end

  def submit_registration(**fields)
    post '/register', {name: 'New Researcher', login: 'new_researcher', email: 'researcher@example.com'}.merge(fields)
  end

  it 'uses the environment flag and lets the stored configuration override it' do
    previous=ENV['SELF_REGISTRATION']
    ENV['SELF_REGISTRATION']='yes'
    Buhos::Configuration.where(id: 'SELF_REGISTRATION').delete
    get '/login'
    expect(Nokogiri::HTML(last_response.body).at_css('a[href="/register"]')).not_to be_nil
    expect(Buhos::Configuration.self_registration?).to be true

    Buhos::Configuration.set('SELF_REGISTRATION', 'false')
    get '/login'
    expect(Nokogiri::HTML(last_response.body).at_css('a[href="/register"]')).to be_nil
    get '/register'
    expect(last_response.status).to eq(404)
    submit_registration
    expect(last_response.status).to eq(404)
    expect(RegistrationRequest.count).to eq(0)
  ensure
    ENV['SELF_REGISTRATION']=previous
  end

  it 'queues valid requests without creating accounts and rejects taken or reserved identifiers' do
    get '/register'
    expect(last_response).to be_ok
    submit_registration(login: 'NEW_RESEARCHER', email: 'Researcher@Example.COM')
    expect(last_response).to be_redirect
    registration=RegistrationRequest.first
    expect([registration.login, registration.email, registration.status]).to eq(%w[new_researcher researcher@example.com pending])
    expect(User[login: registration.login]).to be_nil
    expect(Mail::TestMailer.deliveries).to be_empty

    submit_registration(login: 'ADMIN', email: 'other@example.com')
    expect(last_response.status).to eq(422)
    submit_registration(login: 'another_login', email: 'RESEARCHER@example.com')
    expect(last_response.status).to eq(422)
    submit_registration(email: 'other@example.com')
    expect(last_response.status).to eq(422)
    expect(RegistrationRequest.count).to eq(1)
  end

  it 'allows a user administrator to approve and the applicant to set a password once' do
    submit_registration
    registration=RegistrationRequest.first
    path="/admin/registration_requests/#{registration.id}"
    login_analyst
    get '/admin/registration_requests'
    expect(last_response.status).to eq(403)
    post path, decision: 'approved'
    expect(last_response.status).to eq(403)

    login_admin
    get '/admin/registration_requests'
    expect(last_response.body).to include(registration.email)
    post path, decision: 'approved'
    expect(last_response).to be_redirect
    account=registration.refresh.user
    expect(account.role_id).to eq('independent_researcher')
    expect(registration.status).to eq('approved')
    message=Mail::TestMailer.deliveries.fetch(0)
    expect(message.to).to eq([account.email])
    expect(message.body.decoded).to include("http://example.org/reset_link?t=#{account.token_password}")

    clear_cookies
    token=account.token_password
    get '/reset_link', t: token
    expect(last_response).to be_ok
    post '/reset_link', t: token, user_id: account.id, password: 'first-password', repeat_password: 'first-password'
    expect(account.refresh.correct_password?('first-password')).to be true
    post '/reset_link', t: token, user_id: account.id, password: 'replay', repeat_password: 'replay'
    expect(account.refresh.correct_password?('first-password')).to be true
    post '/reset_link', user_id: account.id, password: 'missing-token', repeat_password: 'missing-token'
    expect(account.refresh.correct_password?('first-password')).to be true
    post '/login', user: account.login, password: 'first-password'
    get '/review/new'
    expect(last_response).to be_ok
  end

  it 'rejects an expired password setup token even when posted directly' do
    submit_registration
    registration=RegistrationRequest.first
    login_admin
    post "/admin/registration_requests/#{registration.id}", decision: 'approved'
    account=registration.refresh.user
    account.update(token_datetime: Time.now - 31*60)

    clear_cookies
    post '/reset_link', t: account.token_password, user_id: account.id, password: 'expired', repeat_password: 'expired'
    expect(last_response).to be_redirect
    expect(account.refresh.correct_password?('expired')).to be false
  end

  it 'sends a standard rejection without creating an account and releases the pending identifiers' do
    submit_registration
    registration=RegistrationRequest.first
    login_admin
    post "/admin/registration_requests/#{registration.id}", decision: 'rejected'
    expect(last_response).to be_redirect
    expect(registration.refresh.status).to eq('rejected')
    expect(User[login: registration.login]).to be_nil
    expect(Mail::TestMailer.deliveries.fetch(0).body.decoded).to include('was not approved')

    clear_cookies
    submit_registration
    expect(last_response).to be_redirect
    expect(RegistrationRequest.where(status: 'pending').count).to eq(1)
  end

  it 'retains the approval when SMTP fails and allows retrying the notification' do
    submit_registration
    registration=RegistrationRequest.first
    login_admin
    path="/admin/registration_requests/#{registration.id}"
    mailer=OutgoingEmail.new
    allow(OutgoingEmail).to receive(:new).and_return(mailer)
    allow(mailer).to receive(:send_email).and_return(false)
    post path, decision: 'approved'
    expect(registration.refresh.status).to eq('approved')
    expect(registration.notified_at).to be_nil

    allow(mailer).to receive(:send_email).and_call_original
    post path, decision: 'retry'
    expect(registration.refresh.notified_at).not_to be_nil
    expect(User.where(login: registration.login).count).to eq(1)
    expect(Mail::TestMailer.deliveries.size).to eq(1)
  end
end

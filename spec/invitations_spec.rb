require_relative 'spec_helper'
require 'mail'

describe 'External invitations' do
  include RSpecMixin

  before do
    configure_empty_database
    login_admin
    @sender=User[1]
    @review=SystematicReview.create(name: 'External review', group_id: @sender.groups.first.id, sr_administrator: @sender.id)
    @path="/review/#{@review.id}/invitations"
    Mail::TestMailer.deliveries.clear
  end

  def invitation(name='New Person', email='new@example.com')
    Invitation.create(name: name, email: email, token: SecureRandom.hex(32), language: 'en',
                      systematic_review_id: @review.id, sender_id: @sender.id, email_sent: true)
  end

  def visit_public(record)
    clear_cookies
    @public_path="/invitation/#{record.token}"
    get @public_path
  end

  it 'prepares the requested number of rows and sends personalized public links' do
    get @path, count: 3
    expect(last_response).to be_ok
    page=Nokogiri::HTML(last_response.body)
    expect(page.css('input[name="names[]"]').size).to eq(3)
    expect(page.css('input[name="emails[]"]').size).to eq(3)

    post @path, names: ['New Person', 'Other Person'], emails: ['NEW@example.com', 'other@example.com']
    expect(last_response).to be_redirect
    expect(Invitation.count).to eq(2)
    expect(Mail::TestMailer.deliveries.size).to eq(2)
    record=Invitation[email: 'new@example.com']
    expect(record.email_sent).to eq(true)
    expect(record.decision).to eq('pending')
    expect(record.token).to match(/\A[0-9a-f]{64}\z/)
    expect(Mail::TestMailer.deliveries.first.body.decoded).to include('New Person', @review.name, "http://example.org/invitation/#{record.token}")
    visit_public(record)
    expect(last_response).to be_ok
    expect(last_response.body).to include('Welcome, New Person', 'Accept', 'Decline')
    expect(User.where(email: record.email).count).to eq(0)
  end

  it 'shows only the count and language form before preparing invitations' do
    get @path
    expect(last_response).to be_ok
    page=Nokogiri::HTML(last_response.body)
    expect(page.css('input[name=count]').size).to eq(1)
    expect(page.at_css('input[name=count]')['value'].to_s).to eq('')
    expect(page.css('select[name=language] option').map { |option| option['value'] }).to eq(%w[es en])
    expect(page.css('input[name="names[]"], input[name="emails[]"], blockquote, form[method=post]')).to be_empty
  end

  it 'previews the selected language and retains it on validation errors' do
    get @path, count: 2, language: 'es'
    page=Nokogiri::HTML(last_response.body)
    expect(page.css('input[name="names[]"]').size).to eq(2)
    expect(page.at_css('blockquote').text).to include('Estimado/a')
    expect(page.at_css('input[type=hidden][name=language]')['value']).to eq('es')
    post @path, names: ['Persona'], emails: ['invalid'], language: 'es'
    expect(last_response.status).to eq(400)
    page=Nokogiri::HTML(last_response.body)
    expect(page.at_css('input[type=hidden][name=language]')['value']).to eq('es')
    expect(page.at_css('input[name="names[]"]')['value']).to eq('Persona')
  end

  it 'rejects invalid invitation counts and languages' do
    ['0', '101', 'bad'].each do |count|
      get @path, count: count, language: 'en'
      expect(last_response.status).to eq(400)
      expect(Nokogiri::HTML(last_response.body).css('input[name="names[]"]')).to be_empty
    end
    post @path, names: ['New'], emails: ['new@example.com'], language: 'invalid'
    expect(last_response.status).to eq(400)
    expect(Invitation.count).to eq(0)
    expect(Mail::TestMailer.deliveries).to be_empty
  end

  it 'records a decline, shows goodbye and notifies the administrator once' do
    record=invitation
    visit_public(record)
    post "#{@public_path}/decision", decision: 'rejected'
    expect(last_response).to be_redirect
    follow_redirect!
    expect(last_response.body).to include('Goodbye')
    expect(record.refresh.decision).to eq('rejected')
    expect(Message.where(user_to: @sender.id).count).to eq(1)
    expect(Message.first.text).to include('declined', record.email, @review.name)
    post "#{@public_path}/decision", decision: 'accepted'
    expect(record.refresh.decision).to eq('rejected')
    expect(Message.count).to eq(1)
    expect(User.where(email: record.email).count).to eq(0)
  end

  it 'sends the requested Spanish wording and opens the public page in Spanish' do
    post @path, names: ['María Pérez'], emails: ['maria@example.com'], language: 'es'

    expect(last_response).to be_redirect
    record=Invitation.first
    expect(record.language).to eq('es')
    link="http://example.org/invitation/#{record.token}"
    expect(Mail::TestMailer.deliveries.first.body.decoded).to eq("Estimado/a María Pérez: Te invito a participar de la revisión sistemática External review. Ingresa a la página #{link} para indicar si deseas aceptar o rechazar su invitación. Gracias")
    visit_public(record)
    expect(last_response).to be_ok
    expect(Nokogiri::HTML(last_response.body).text).to include('Bienvenido/a, María Pérez', 'Aceptar', 'Rechazar')
  end

  it 'suggests a lowercase login with a suffix when necessary and permits changing it' do
    record=invitation('New Person')
    User.create(login: 'newperson', name: 'Existing', password: 'hash', role_id: 'analyst')
    visit_public(record)
    post "#{@public_path}/decision", decision: 'accepted'
    expect(record.refresh.decision).to eq('accepted')
    follow_redirect!
    expect(last_response).to be_ok
    expect(Nokogiri::HTML(last_response.body).at_css('input[name=login]')['value']).to eq('newperson1')

    post "#{@public_path}/register", login: 'chosenlogin', password: 'secret', repeat_password: 'secret'
    expect(last_response).to be_redirect
    account=User[login: 'chosenlogin']
    expect(account.name).to eq(record.name)
    expect(account.email).to eq(record.email)
    expect(account.role_id).to eq('analyst')
    expect(account.correct_password?('secret')).to eq(true)
    expect(account.groups.map(&:id)).to include(@review.group_id)
    expect(record.refresh.user_id).to eq(account.id)
    expect(SystematicReviewUserData[user_id: account.id, systematic_review_id: @review.id].invitation_sent).to eq(true)
    expect(Message.count).to eq(1)
    expect(Message.first.text).to include('accepted')
    follow_redirect!
    expect(last_response.body).to include('Your account was created')
    post "#{@public_path}/register", login: 'secondaccount', password: 'secret', repeat_password: 'secret'
    expect(last_response.status).to eq(409)
    expect(User[login: 'secondaccount']).to be_nil
    post '/login', user: 'chosenlogin', password: 'secret'
    expect(last_response).to be_redirect
    get '/'
    expect(last_response.body).to include(@review.name)
  end

  it 'validates login collisions, blank passwords and repetition without creating partial accounts' do
    record=invitation
    visit_public(record)
    post "#{@public_path}/decision", decision: 'accepted'
    existing=User.first.login
    [[existing, 'secret', 'secret'], ['freshlogin', '', ''], ['freshlogin', 'secret', 'different'], ['bad login', 'secret', 'secret']].each do |login, password, repeated|
      post "#{@public_path}/register", login: login, password: password, repeat_password: repeated
      expect(last_response.status).to eq(422)
      expect(record.refresh.user_id).to be_nil
      expect(User.where(email: record.email).count).to eq(0)
      expect(last_response.body).not_to include('value="secret"')
    end
  end

  it 'does not allow registration before acceptance or access to unknown tokens' do
    record=invitation
    visit_public(record)
    post "#{@public_path}/register", login: 'newperson', password: 'secret', repeat_password: 'secret'
    expect(last_response.status).to eq(409)
    get "/invitation/#{'a'*64}"
    expect(last_response.status).to eq(404)
    expect(User.where(email: record.email).count).to eq(0)
  end

  it 'rejects invalid rows, duplicates and existing accounts before sending anything' do
    User.first.update(email: 'exists@example.com')
    [ [['Person'], ['invalid']], [[''], ['new@example.com']], [['One', 'Two'], ['one@example.com', 'one@example.com']], [['Existing'], ['exists@example.com']] ].each do |names, emails|
      post @path, names: names, emails: emails
      expect(last_response.status).to eq(400)
    end
    expect(Invitation.count).to eq(0)
    expect(Mail::TestMailer.deliveries).to be_empty
  end

  it 'allows retrying failed email with the same token, then prevents duplicate sending' do
    allow_any_instance_of(OutgoingEmail).to receive(:send_email).and_return(false)
    post @path, names: ['New Person'], emails: ['new@example.com']
    record=Invitation.first
    token=record.token
    expect(record.email_sent).to eq(false)
    allow_any_instance_of(OutgoingEmail).to receive(:send_email).and_call_original
    post @path, names: ['New Person'], emails: ['new@example.com']
    expect(record.refresh.email_sent).to eq(true)
    expect(record.token).to eq(token)
    expect(Invitation.count).to eq(1)
    post @path, names: ['New Person'], emails: ['new@example.com']
    expect(last_response.status).to eq(400)
    expect(Mail::TestMailer.deliveries.size).to eq(1)
  end

  it 'denies invitation management to an analyst and keeps management private' do
    login_analyst
    get @path
    expect(last_response.status).to eq(403)
    post @path, names: ['New Person'], emails: ['new@example.com']
    expect(last_response.status).to eq(403)
    clear_cookies
    get @path
    expect(last_response.body).not_to include('name="names[]"')
    expect(Invitation.count).to eq(0)
  end
end

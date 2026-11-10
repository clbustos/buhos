require_relative 'spec_helper'
require 'mail'

describe 'Review messages to selected members' do
  include RSpecMixin

  before do
    configure_empty_database
    login_admin
    @sender=User[1]
    @group=@sender.groups.first
    @members=@group.users.sort_by(&:id)
    @members.each { |member| member.update(email: "user#{member.id}@example.com") }
    @review=SystematicReview.create(name: 'Message review', group_id: @group.id, sr_administrator: @sender.id)
    @path="/review/#{@review.id}/messages"
    Mail::TestMailer.deliveries.clear
  end

  def send_messages(ids, subject='Please join', text='Welcome to the review')
    post @path, user_ids: ids, subject: subject, text: text
  end

  it 'shows the group members and form without invitation status' do
    sent=@members.first
    SystematicReviewUserData.create(user_id: sent.id, systematic_review_id: @review.id, invitation_sent: true)
    get @path

    expect(last_response).to be_ok
    page=Nokogiri::HTML(last_response.body)
    expect(page.css('.message-recipient').map { |node| node['value'].to_i }.sort).to eq(@members.map(&:id))
    expect(page.text).not_to include('Invitation status')
    expect(page.css('input[name=subject]').size).to eq(1)
    expect(page.css('textarea[name=text]').size).to eq(1)
    get '/'
    buttons=Nokogiri::HTML(last_response.body).css("a[href='#{@path}']")
    expect(buttons).not_to be_empty
    expect(buttons.first.previous_element['href']).to eq("/review/#{@review.id}/invitations")
  end

  it 'sends emails and personal messages to selected members only and preserves dashboard order' do
    recipient=@members.last
    data=SystematicReviewUserData.create(user_id: recipient.id, systematic_review_id: @review.id, dashboard_order: 7)
    send_messages([recipient.id])

    expect(last_response).to be_redirect
    expect(Mail::TestMailer.deliveries.size).to eq(1)
    email=Mail::TestMailer.deliveries.first
    expect(email.to).to eq([recipient.email])
    expect(email.subject).to eq('Please join')
    expect(email.body.decoded).to include('Welcome to the review', @review.name, "http://example.org/review/#{@review.id}/dashboard")
    message=Message.where(user_to: recipient.id).first
    expect(Message.count).to eq(1)
    expect(message.user_from).to eq(@sender.id)
    expect(message.text).to eq(email.body.decoded)
    expect(message.viewed).to eq(false)
    expect(data.refresh.invitation_sent).to eq(false)
    expect(data.dashboard_order).to eq(7)
  end

  it 'preserves a previously sent invitation when sending a regular message' do
    recipient=@members.first
    data=SystematicReviewUserData.create(user_id: recipient.id, systematic_review_id: @review.id, invitation_sent: true)
    send_messages([recipient.id])

    expect(last_response).to be_redirect
    expect(data.refresh.invitation_sent).to eq(true)
  end

  it 'keeps Invitations separate from Messages' do
    get "/review/#{@review.id}/invitations"
    expect(last_response).to be_ok
    page=Nokogiri::HTML(last_response.body)
    expect(page.css('input[name="names[]"]')).to be_empty
    expect(page.css('select[name=language]').size).to eq(1)
    expect(page.css('.message-recipient')).to be_empty
  end

  it 'can send to all checked members, without duplicate sends for repeated IDs' do
    send_messages(@members.map(&:id) + [@members.first.id])

    expect(last_response).to be_redirect
    expect(Mail::TestMailer.deliveries.size).to eq(@members.size)
    expect(Message.count).to eq(@members.size)
    expect(SystematicReviewUserData.count).to eq(0)
  end

  it 'delivers internal messages and continues when an email fails' do
    failing=@members.first
    allow_any_instance_of(OutgoingEmail).to receive(:send_email).and_call_original
    allow_any_instance_of(OutgoingEmail).to receive(:send_email).with(failing.email, anything, anything).and_return(false)
    send_messages(@members.map(&:id))

    expect(last_response).to be_redirect
    expect(SystematicReviewUserData.where(user_id: failing.id, invitation_sent: true).count).to eq(0)
    expect(Message.count).to eq(@members.size)
    expect(Mail::TestMailer.deliveries.size).to eq(@members.size - 1)
    follow_redirect!
    expect(last_response.body).to include('Could not send email to:', failing.name)
  end

  it 'does not attempt email for a member without an email address' do
    recipient=@members.first
    recipient.update(email: nil)
    expect_any_instance_of(OutgoingEmail).not_to receive(:send_email)
    send_messages([recipient.id])

    expect(last_response).to be_redirect
    expect(Message.where(user_to: recipient.id).count).to eq(1)
    expect(SystematicReviewUserData.where(invitation_sent: true).count).to eq(0)
  end

  it 'reports SMTP exceptions without modifying invitation data' do
    allow_any_instance_of(OutgoingEmail).to receive(:send_email).and_raise(StandardError, 'SMTP unavailable')
    send_messages([@members.first.id])

    expect(last_response).to be_redirect
    expect(Message.count).to eq(1)
    expect(SystematicReviewUserData.where(invitation_sent: true).count).to eq(0)
    follow_redirect!
    expect(last_response.body).to include('Could not send email to:')
  end

  it 'shows an empty group and disables sending when there are no members' do
    empty_group=Group.create(name: 'Empty invitation group', group_administrator: @sender.id)
    @review.update(group_id: empty_group.id)
    get @path

    expect(last_response).to be_ok
    page=Nokogiri::HTML(last_response.body)
    expect(page.css('.message-recipient')).to be_empty
    expect(page.at_css('button[type=submit]')['disabled']).not_to be_nil
  end

  it 'rejects missing selection, outsiders, blank content and multiline subjects before sending' do
    outsider=User.create(login: 'outside', password: 'password', name: 'Outside', role_id: 'analyst')
    [[], [outsider.id], ['invalid']].each do |ids|
      send_messages(ids)
      expect(last_response.status).to eq(400)
    end
    [['', 'Body'], ['Subject', ' '], ["Subject\nBcc: other@example.com", 'Body']].each do |subject, text|
      send_messages([@members.first.id], subject, text)
      expect(last_response.status).to eq(400)
    end
    expect(Mail::TestMailer.deliveries).to be_empty
    expect(Message.count).to eq(0)
    expect(SystematicReviewUserData.count).to eq(0)
  end

  it 'keeps the history visible but denies bulk sending without review editing permission' do
    login_analyst
    get @path
    expect(last_response).to be_ok
    expect(Nokogiri::HTML(last_response.body).css('.message-recipient')).to be_empty
    send_messages([@members.first.id])
    expect(last_response.status).to eq(403)
    expect(Mail::TestMailer.deliveries).to be_empty
    expect(Message.count).to eq(0)
  end
end

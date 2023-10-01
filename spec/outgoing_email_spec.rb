require 'spec_helper'
require_relative "../lib/outgoing_email"
require 'mail'
describe 'Outgoing Email:' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    configure_empty_sqlite
    login_admin

  end
  context "when email is sent" do
    before(:context) do
      ENV['SMTP_USER']="test@test.com"

      Mail::TestMailer.deliveries.clear()
      om=OutgoingEmail.new()
      email_to="test@test.com"
      subject_message="subject_message"
      message="message"
      @status_om=om.send_email(email_to,subject_message,message)
    end
    it "send_mail should return true" do
      expect(@status_om).to be true
    end
    it "should send 1 correct email" do
      # Check if the email was sent
      expect(Mail::TestMailer.deliveries.length).to eq(1)

      # Access the sent email for further assertions
      sent_email = Mail::TestMailer.deliveries.first

      # Perform assertions on the sent email
      expect(sent_email.to).to include('test@test.com')
      expect(sent_email.subject).to eq('subject_message')
      expect(sent_email.body.to_s).to include('message')
    end
  end

  context "when email is sent, but no smtp_user is defined" do
    before(:context) do
      ENV['SMTP_USER']=nil
      Mail::TestMailer.deliveries.clear()
      om=OutgoingEmail.new()
      email_to="test@test.com"
      subject_message="subject_message"
      message="message"
      @status_om=om.send_email(email_to,subject_message,message)
    end
    it "send_mail should return true" do
      expect(@status_om).to be false
    end
    after(:context) do
      ENV['SMTP_USER']="test@test.com"

    end
  end


end
require_relative 'spec_helper'
require 'mail'

describe Buhos::Configuration do
  include RSpecMixin

  before(:all) { configure_empty_database }

  around do |example|
    keys = %w[SMTP_SERVER SMTP_USER SMTP_PASSWORD SMTP_SECURITY SMTP_PORT]
    previous = ENV.to_h.slice(*keys)
    keys.each { |key| ENV.delete(key) }
    example.run
  ensure
    keys.each { |key| ENV.delete(key) }
    ENV.update(previous)
    Buhos::Configuration.where(id: keys).delete
  end

  it 'uses environment settings when no database value exists' do
    ENV.update('SMTP_SERVER' => 'env.example.com', 'SMTP_USER' => 'env@example.com',
               'SMTP_PASSWORD' => 'env-password', 'SMTP_SECURITY' => 'STARTTLS', 'SMTP_PORT' => '587')
    expect(described_class.smtp_settings).to eq(server: 'env.example.com', user: 'env@example.com',
                                               password: 'env-password', security: 'STARTTLS', port: '587')
  end

  it 'prefers database values and falls back independently for each setting' do
    ENV.update('SMTP_SERVER' => 'env.example.com', 'SMTP_PORT' => '587', 'SMTP_PASSWORD' => 'env-password')
    described_class.set('SMTP_SERVER', 'db.example.com')
    described_class.set('SMTP_PASSWORD', '')
    expect(described_class.smtp_settings).to eq(server: 'db.example.com', user: nil,
                                               password: '', security: nil, port: '587')
  end

  it 'sends email using the sender stored in the database' do
    ENV['SMTP_USER'] = 'env@example.com'
    described_class.set('SMTP_USER', 'db@example.com')
    Mail::TestMailer.deliveries.clear
    expect(OutgoingEmail.new.send_email('recipient@example.com', 'Test', 'Message')).to be true
    expect(Mail::TestMailer.deliveries.last.from).to eq(['db@example.com'])
  end

  it 'enables password recovery with a database SMTP server' do
    described_class.set('SMTP_SERVER', 'db.example.com')
    helper = Object.new.extend(Sinatra::SessionAuth::Helpers)
    expect(helper.allow_password_recovery?).to be true
    described_class.set('SMTP_SERVER', '')
    expect(helper.allow_password_recovery?).to be false
  end
end

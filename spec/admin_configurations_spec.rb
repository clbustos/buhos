require_relative 'spec_helper'

describe 'Site configurations' do
  include RSpecMixin

  before(:all) { configure_empty_database }

  it 'stores and updates settings through the model' do
    expect(Buhos::Configuration.get('missing')).to be_nil
    Buhos::Configuration.set('site_title', 'First title')
    expect(Buhos::Configuration.get('site_title')).to eq('First title')
    Buhos::Configuration.set('site_title', 'New title')
    expect(Buhos::Configuration.get('site_title')).to eq('New title')
  end

  it 'lets administrators view and save settings safely' do
    login_admin
    get '/admin/configurations'
    expect(last_response).to be_ok
    expect(last_response.body).to include('/admin/configurations')
    post '/admin/configurations/update', key: 'site_title', value: '<script>alert(1)</script>'
    expect(last_response.status).to eq(302)
    follow_redirect!
    expect(last_response.body).to include('&lt;script&gt;')
    expect(Buhos::Configuration.get('site_title')).to eq('<script>alert(1)</script>')
    post '/admin/configurations/update', key: 'site_title', value: ''
    expect(Buhos::Configuration.get('site_title')).to eq('')
  end

  it 'rejects empty keys' do
    login_admin
    post '/admin/configurations/update', key: ' ', value: 'test'
    expect(last_response.status).to eq(400)
    expect(Buhos::Configuration[' ']).to be_nil
  end

  it 'denies analysts access and changes' do
    login_analyst
    get '/admin/configurations'
    expect(last_response.status).to eq(403)
    post '/admin/configurations/update', key: 'forbidden', value: 'test'
    expect(last_response.status).to eq(403)
    expect(Buhos::Configuration['forbidden']).to be_nil
  end
end

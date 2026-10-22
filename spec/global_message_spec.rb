require_relative 'spec_helper'

describe 'Global message' do
  before(:all) do
    RSpec.configure { |config| config.include RSpecMixin }
  end

  around do |example|
    previous_global_message = ENV['GLOBAL_MESSAGE']
    example.run
  ensure
    previous_global_message.nil? ? ENV.delete('GLOBAL_MESSAGE') : ENV['GLOBAL_MESSAGE'] = previous_global_message
  end

  it 'is hidden when GLOBAL_MESSAGE is not set' do
    ENV.delete('GLOBAL_MESSAGE')

    get '/login'

    expect(last_response.body).not_to include('global-message')
  end

  it 'appears in the page header when GLOBAL_MESSAGE is set' do
    ENV['GLOBAL_MESSAGE'] = 'Scheduled maintenance tonight'

    get '/login'

    expect(last_response.body).to include('global-message')
    expect(last_response.body).to include('Scheduled maintenance tonight')
  end

  it 'escapes HTML from GLOBAL_MESSAGE' do
    ENV['GLOBAL_MESSAGE'] = '<script>alert("unsafe")</script>'

    get '/login'

    expect(last_response.body).to include('&lt;script&gt;alert(&quot;unsafe&quot;)&lt;&#x2F;script&gt;')
    expect(last_response.body).not_to include('<script>alert("unsafe")</script>')
  end
end

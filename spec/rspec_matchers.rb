RSpec::Matchers.define :responds_with_no_review_id_error do |code|
  match do |actual|
    get actual
    expect(last_response.status).to eq(404)
    expect(last_response.body).to include(code.to_s)
    expect(last_response.body).to include(I18n::t(:Systematic_review))
  end
  description do
    "route #{actual} responds with 404 status, and a message with code object and code #{code}"
  end

  failure_message do |actual|
    "expected route '#{actual}' to responds with 404 status, but responds in another way"
  end
end


RSpec::Matchers.define :responds_with_no_user_id_error do |code|
  match do |actual|
    get actual
    expect(last_response.status).to eq(404)
    expect(last_response.body).to include(code.to_s)
    expect(last_response.body).to include(I18n::t(:User))
  end
  failure_message do |actual|
    "expected route '#{actual}' to responds with 404 status, but responds in another way"
  end
  description do
    "route #{actual} responds with 404 status, and a message with code object and code #{code}"
  end

end

RSpec::Matchers.define :responds_with_no_search_id_error do |code|
  match do |actual|
    get actual
    expect(last_response.status).to eq(404)
    expect(last_response.body).to include(code.to_s)
    expect(last_response.body).to include(I18n::t(:Search))
  end
  failure_message do |actual|
    "expected route '#{actual}' to responds with 404 status, but responds in another way"
  end
  description do
    "route #{actual} responds with 404 status, and a message with code object and code #{code}"
  end

end

RSpec::Matchers.define :responds_with_no_cd_id_error do |code|
  match do |actual|
    get actual
    expect(last_response.status).to eq(404)
    expect(last_response.body).to include(code.to_s)
    expect(last_response.body).to include(I18n::t(:Canonical_document))
  end
  failure_message do |actual|
    "expected route '#{actual}' to responds with 404 status, but responds in another way"
  end
  description do
    "route #{actual} responds with 404 status, and a message with code object and code #{code}"
  end

end

RSpec::Matchers.define :responds_with_no_tag_id_error do |code|
  match do |actual|
    get actual
    expect(last_response.status).to eq(404)
    expect(last_response.body).to include(code.to_s)
    expect(last_response.body).to include(I18n::t(:Tag))
  end
  failure_message do |actual|
    "expected route '#{actual}' to responds with 404 status, but responds in another way"
  end
  description do
    "route #{actual} responds with 404 status, and a message with code object and code #{code}"
  end

end

RSpec::Matchers.define :be_accesible_for_admin do
  match do |actual|
    post '/login' , :user=>'admin', :password=>'admin'
    get actual
    #puts last_response.body
    expect(last_response).to be_ok
    expect(last_response.body).to_not be_empty
  end

  match_when_negated do |actual|
    post '/login' , :user=>'admin', :password=>'admin'
    get actual
    expect(last_response).to_not be_ok
  end
  description do
    "route #{actual} be accesible for admin"
  end


  failure_message do |actual|
    last_response.body=~/<section id='content'>(.+?)<\/section>/m
    show_body=$1.nil? ? last_response.body : $1
    "expected #{actual} be accessible, but status was #{last_response.status} and content was '#{show_body}'"
  end
end


RSpec::Matchers.define :be_accesible do
  match do |actual|
    get actual
    #puts last_response.body
    expect(last_response).to be_ok
    expect(last_response.body).to_not be_empty
  end

  match_when_negated do |actual|
    get actual
    expect(last_response).to_not be_ok
  end
  description do
    "route #{actual} be accesible"
  end
end

RSpec::Matchers.define :be_prohibited do
  match do |actual|
    get actual
    expect(last_response).to_not be_ok
    expect(last_response.status).to eq(403)
  end

  description do
    "route #{actual} be prohibited"
  end
end


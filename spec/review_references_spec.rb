require 'spec_helper'

describe 'Review references resources' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    @temp=configure_empty_database
    login_admin
    pre_context
  end

  after(:all) do
    after_context
  end

  def reference_text_1
    "Smith J. First reference for review references spec. Journal of Tests. 2020;1:1-2."
  end

  def reference_text_2
    "Doe J. Reference without canonical document. Journal of Specs. 2021;2:3-4."
  end

  def pre_context
    sr_for_report
    CanonicalDocument[1].update(:title=>"Canonical document for review references spec")
    create_references(texts: [reference_text_1, reference_text_2],
                      cd_id: [1, nil],
                      record_id: 1)
  end

  def after_context
    SystematicReview[1].delete
    $db[:records_references].delete
    $db[:records_searches].delete
    $db[:records].delete
    $db[:bib_references].delete
    $db[:canonical_documents].delete
    $db[:searches].delete
  end

  def reference_with_canonical
    Reference.get_by_text(reference_text_1)
  end

  def reference_without_canonical
    Reference.get_by_text(reference_text_2)
  end

  context 'when review references are listed' do
    before(:context) do
      get '/review/1/references'
    end

    it 'response should be ok' do
      expect(last_response).to be_ok
    end

    it 'should show references from the review' do
      expect(last_response.body).to include(reference_text_1)
      expect(last_response.body).to include(reference_text_2)
    end
  end

  context 'when review references are filtered by text' do
    before(:context) do
      get '/review/1/references', query: 'without canonical'
    end

    it 'response should be ok' do
      expect(last_response).to be_ok
    end

    it 'should show matching references' do
      expect(last_response.body).to include(reference_text_2)
    end
  end

  context 'when only references without canonical document are requested' do
    before(:context) do
      get '/review/1/references', wo_canonical: 'true'
    end

    it 'response should be ok' do
      expect(last_response).to be_ok
    end

    it 'should not show references with canonical document' do
      expect(last_response.body).to_not include(reference_text_1)
      expect(last_response.body).to include(reference_text_2)
    end
  end

  context 'when a review reference is retrieved' do
    before(:context) do
      get "/review/1/reference/#{reference_with_canonical.id}"
    end

    it 'response should be ok' do
      expect(last_response).to be_ok
    end

    it 'should show the reference text' do
      expect(last_response.body).to include(reference_text_1)
    end
  end

  context 'when manual canonical assignment is selected' do
    before(:context) do
      post '/review/1/references/actions',
           reference: {reference_without_canonical.id=> '1'},
           user_id: 1,
           action: 'assigncdmanual'
    end

    it 'response should be redirect' do
      expect(last_response).to be_redirect
    end

    it 'should redirect to create canonical document for references' do
      expect(last_response.header['Location']).to include('/review/1/assign_canonical_to_references')
      expect(last_response.header['Location']).to include(reference_without_canonical.id)
    end
  end

  context 'when canonical document is removed from references' do
    before(:context) do
      reference_with_canonical.update(canonical_document_id: 1)
      post '/review/1/references/actions',
           reference: {reference_with_canonical.id=> '1'},
           user_id: 1,
           action: 'removecd'
    end

    it 'response should be redirect' do
      expect(last_response).to be_redirect
    end

    it 'should remove canonical document from reference' do
      expect(reference_with_canonical.reload.canonical_document_id).to be_nil
    end
  end

  context 'when a canonical document is created for references' do
    before(:context) do
      reference_without_canonical.update(canonical_document_id: nil)
      post '/review/1/create_canonical_for_references',
           references: {reference_without_canonical.id=> 'true'},
           author: 'Manual Author',
           year: 2026,
           title: 'Manual canonical title'
    end

    it 'response should be redirect' do
      expect(last_response).to be_redirect
    end

    it 'should assign the new canonical document to reference' do
      cd=CanonicalDocument[reference_without_canonical.reload.canonical_document_id]
      expect(cd.title).to eq('Manual canonical title')
    end
  end
end

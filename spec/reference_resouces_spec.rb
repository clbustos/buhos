require 'spec_helper'

describe 'Reference resources' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    @temp=configure_empty_sqlite
    sr_for_report
    @ref_1="Al-Zubidy A, Carver JC. Identification and prioritization of SLR search tool requirements: an SLR and a survey. Empir Softw Eng. 2018;1–31"
    @ref_2="Al-Zubidy A, Carver JC, Hale DP, Hassler EE. Vision for SLR tooling infrastructure: Prioritizing value-added requirements. Inf Softw Technol. Elsevier; 2017 Nov 1;91:72–81."
    @ref_3="Al-Zubidy , Carver , Hale , Hassler EE. Vision for SLR tooling infrastructure: Prioritizing value-added requirements. Inf Softw Technol. Elsevier; 2017 1;91:72–81."
    create_references(texts:[@ref_1,@ref_2 , @ref_3], record_id:1)
    CanonicalDocument[1].update(title:"Identification and prioritization of SLR search tool requirements: an SLR and a survey")
    Reference.get_by_text(@ref_1).update(doi:"10.1016/J.INFSOF.2017.06.007")
    login_admin
  end
  def reference_doi
    Reference.get_by_text(@ref_1)
  end
  def reference_wo_doi
    Reference.get_by_text(@ref_2)
  end

  context 'when reference with DOI is retrieved' do
    before(:context) do
      get "/reference/#{reference_doi[:id]}"
    end
    it "should response be ok" do
      expect(last_response).to be_ok
    end
    it "should show its code" do
      expect(last_response.body).to include(reference_doi[:id])
    end
    it "should show its DOI" do
      expect(last_response.body).to include(reference_doi[:doi])
    end

  end

  context "when similar references are retrieved from a reference with canonical" do
    before(:context) do
      get "/reference/#{reference_doi[:id]}/search_similar?distancia=10"
    end
    it "should response be ok" do
      expect(last_response).to be_ok
    end
    it "should show its code" do
      expect(last_response.body).to include(reference_doi[:id])
    end
    it "should show that are nothing similar without canonical" do
      expect(last_response.body).to include(I18n::t(:No_similar_references_without_canonical))
    end

  end

  context "when similar references are retrieved from a reference without canonical and similar reference" do
    before(:context) do
      get "/reference/#{reference_wo_doi[:id]}/search_similar?distancia=20"
    end
    it "should response be ok" do
      expect(last_response).to be_ok
    end
    it "should show its code" do
      expect(last_response.body).to include(reference_wo_doi[:id])
    end
    it "should show that are similar references without canonical" do
      expect(last_response.body).to_not include(I18n::t(:No_similar_references_without_canonical))
    end
  end

  context "when assign DOI to a reference without it" do
    before(:context) do
      @doi=reference_doi.doi
      reference_doi.update(:doi=>nil)
      get "/reference/#{reference_doi[:id]}/assign_doi/#{@doi.gsub('/','***')}"
    end
    it "response should be redirect" do
      expect(last_response).to be_redirect
    end
    it "reference should have correct doi" do
      expect(reference_doi.doi).to eq(@doi)
    end
  end

  context "when assign canonical document to a reference" do
    before(:context) do
      reference_doi.update(canonical_document_id:nil)
      post '/reference/assign_canonical_document', cd_id:1, ref_id:reference_doi[:id]
    end
    it "response should be redirect" do
      expect(last_response).to be_redirect
    end
    it "reference should have correct doi" do
      expect(reference_doi.canonical_document_id).to eq(1)
    end

    after(:context) do
      reference_doi.update(canonical_document_id:nil)
    end
  end

  context "when mergin similar references" do
    before(:context) do
      $db[:bib_references].update(canonical_document_id:nil)
      r_1=Reference.get_by_text(@ref_1)
      r_1.update(canonical_document_id:1)
      post "/reference/#{r_1.id}/merge_similar_references", reference:{Reference.calculate_id(@ref_2)=>'true', Reference.calculate_id(@ref_3)=>'true' }
    end
    it "response should be redirect" do
      expect(last_response).to be_redirect
    end
    it "all references should have same canonical document" do
      expect(Reference.where(:canonical_document_id=>1).count).to eq(3)
    end
    after(:context) do
      $db[:bib_references].update(canonical_document_id:nil)
    end
  end

  context "on assign canonical document to a reference" do
    before(:context) do
      $db[:bib_references].update(canonical_document_id:nil)
      get "/review/1/reference/#{reference_doi.id}/assign_canonical_document"
    end
    it "response should be ok" do
      expect(last_response).to be_ok
    end
    it "response should include reference text" do
      #p last_response.body
      expect(last_response.body).to include(reference_doi.text)
    end

    it "response should include list of canonical documents if title is set" do
      get "/review/1/reference/#{reference_doi.id}/assign_canonical_document", :query=>{title:"Identification"}
      expect(last_response).to be_ok
      expect(last_response.body).to include(I18n::t(:Count_canonical_documents))
    end

    after(:context) do
      $db[:bib_references].update(canonical_document_id:nil)
    end
  end

end
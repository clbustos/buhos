require_relative 'spec_helper'

# Integration test, that checks the availability of main resources of the system.
# Just test that every page is available

describe 'Resources nonavailability:' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }

    @temp=configure_empty_sqlite

    login_admin
  end



  context "when review resources are accessed" do
    it { expect("/review/1").to responds_with_404}
    it { expect("/review/1/dashboard").to responds_with_404}
    it { expect("/review/1/edit").to responds_with_404}
    it { expect("/review/1/delete").to responds_with_404}
    it { expect("/review/1/canonical_documents").to responds_with_404}
    it { expect("/review/1/repeated_canonical_documents").to responds_with_404}

    it { expect("/review/1/searches").to responds_with_404}
    it { expect("/review/1/tags").to responds_with_404}
    it { expect("/review/1/messages").to responds_with_404}
    it { expect("/review/1/fields").to responds_with_404}
    it { expect("/review/1/files").to responds_with_404}
  end

  context "when review administration resources are accessed" do
    it { expect("/review/1/administration_stages").to responds_with_404}
    it { expect("/review/1/administration/search").to responds_with_404}
    it { expect("/review/1/administration/screening_title_abstract").to responds_with_404}
    it { expect("/review/1/administration/screening_references").to responds_with_404}
    it { expect("/review/1/administration/review_full_text").to responds_with_404}
    it { expect("/review/1/administration/report").to responds_with_404}


    it { expect("/review/1/administration/screening_title_abstract/cd_assignations").to responds_with_404}
    it { expect("/review/1/administration/screening_title_abstract/cd_without_allocations").to responds_with_404}
    it { expect("/review/1/stage/screening_title_abstract/complete_empty_abstract_manual").to responds_with_404}


  end


  context "when review stages resources are accessed" do
    it { expect("/review/1/screening_title_abstract").to responds_with_404}
    it "pager should work on screeing title and abstract" do
      expect("/review/1/screening_title_abstract?search=yes&order=title__asc&pagina=2").to responds_with_404
    end


    it { expect("/review/1/screening_references").to responds_with_404}
    it "pager should work on screening references" do
      expect("/review/1/screening_references?search=yes&order=title__asc&pagina=2").to responds_with_404
    end
    it { expect("/review/1/review_full_text").to responds_with_404}
    it "pager should work on full text review" do
      expect("/review/1/review_full_text?search=yes&order=title__asc&pagina=2").to responds_with_404
    end

  end

  context "when user enter extract information form" do
    it { expect("/review/1/extract_information/cd/137").to responds_with_404}


  end



  context "when review searches resources are accessed" do
    it { expect("/review/1/records").to responds_with_404}
    it { expect("/review/1/records/user/1").to responds_with_404}
    it { expect("/review/1/search/1/record/1/complete_information").to responds_with_404}

    it { expect("/review/1/searches/user/1").to responds_with_404}
    it { expect("/review/1/search/bibliographic_file/new").to responds_with_404}
    it { expect("/review/1/search/uploaded_files/new").to responds_with_404}
    it { expect("/review/1/searches/compare_records").to responds_with_404}
    it { expect("/review/1/searches/analyze").to responds_with_404}
  end


  context "when search resources are accessed" do
    it { expect("/search/1").to responds_with_404}
    it { expect("/search/1/edit").to responds_with_404}
    it { expect("/search/1/records").to responds_with_404}
    it { expect("/search/1/record/1").to responds_with_404}
    it { expect("/search/1/references").to responds_with_404}
  end
  context "when reports are accessed" do
    it { expect("/review/1/report/PRISMA/html").to responds_with_404}
    it { expect("/review/1/report/fulltext/html").to responds_with_404}
    it { expect("/review/1/report/process/html").to responds_with_404}


  end


  context "when records are accessed" do
    it { expect("/record/1").to responds_with_404}
  end
  context "when references are acceded" do
    it {expect("/reference/19e8abd776da3d40aec0158e8ef105959bd9b57bdb5f64ce07ec3d33a0324334").to responds_with_404}
    it {expect("/reference/19e8abd776da3d40aec0158e8ef105959bd9b57bdb5f64ce07ec3d33a0324334/search_similar").to responds_with_404}

  end
  context "when canonical documents resources are accessed" do
    it { expect("/canonical_document/1").to responds_with_404}
    it { expect("/canonical_document/1/search_similar").to responds_with_404}
    it { expect("/canonical_document/1/view_crossref_info").to responds_with_404}
  end

  context "when tag resources are accesed" do
    it {expect("/tag/2/rs/1/cds").to responds_with_404}
    it {expect("/tag/2/rs/1/stage/screening_title_abstract/cds").to responds_with_404}
  end


  after(:all) do
    @temp=nil
  end
end
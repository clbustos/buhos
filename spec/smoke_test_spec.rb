require_relative 'spec_helper'

# Smoke test: preliminary test, that covers the main resources of the system.
# Just test that every page is accesible and throws an error.

describe 'Review with all stages completed' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }

    @temp=configure_complete_sqlite


  end


  it { expect("/").to be_accesible_for_admin}
  context "when admin resources are accessed" do
    it { expect("/admin/users").to be_accesible_for_admin}
    it { expect("/admin/groups").to be_accesible_for_admin}
    it { expect("/admin/roles").to be_accesible_for_admin}
  end

  context "when review resources are accessed" do
    it { expect("/reviews").to be_accesible_for_admin}
    it { expect("/review/new").to be_accesible_for_admin}
    it { expect("/review/1").to be_accesible_for_admin}
    it { expect("/review/1/edit").to be_accesible_for_admin}
    it { expect("/review/1/canonical_documents").to be_accesible_for_admin}
    it { expect("/review/1/repeated_canonical_documents").to be_accesible_for_admin}

    it { expect("/review/1/searchs").to be_accesible_for_admin}
    it { expect("/review/1/tags").to be_accesible_for_admin}
    it { expect("/review/1/messages").to be_accesible_for_admin}
    it { expect("/review/1/fields").to be_accesible_for_admin}
    it { expect("/review/1/files").to be_accesible_for_admin}
  end

  context "when review administration resources are accessed" do
    it { expect("/review/1/administration_stages").to be_accesible_for_admin}
    it { expect("/review/1/administration/search").to be_accesible_for_admin}
    it { expect("/review/1/administration/screening_title_abstract").to be_accesible_for_admin}
    it { expect("/review/1/administration/screening_references").to be_accesible_for_admin}
    it { expect("/review/1/administration/review_full_text").to be_accesible_for_admin}
    it { expect("/review/1/administration/report").to be_accesible_for_admin}


    it { expect("/review/1/administration/screening_title_abstract/cd_assignations").to be_accesible_for_admin}
    it { expect("/review/1/administration/screening_title_abstract/cd_without_assignations").to be_accesible_for_admin}
    it { expect("/review/1/stage/screening_title_abstract/complete_empty_abstract_manual").to be_accesible_for_admin}


  end


  context "when review stages resources are accessed" do
    it { expect("/review/1/screening_title_abstract").to be_accesible_for_admin}
    it "pager should work on screeing title and abstract" do
      expect("/review/1/screening_title_abstract?busqueda=yes&orden=title__asc&pagina=2").to be_accesible_for_admin
    end


    it { expect("/review/1/screening_references").to be_accesible_for_admin}
    it "pager should work on screening references" do
      expect("/review/1/screening_references?busqueda=yes&orden=title__asc&pagina=2").to be_accesible_for_admin
    end
    it { expect("/review/1/review_full_text").to be_accesible_for_admin}
    it "pager should work on full text review" do
      expect("/review/1/review_full_text?busqueda=yes&orden=title__asc&pagina=2").to be_accesible_for_admin
    end

  end

  context "when user enter extract information form" do
    it { expect("/review/1/extract_information/cd/137").to be_accesible_for_admin}


  end



  context "when review searchs resources are accessed" do
    it { expect("/review/1/searchs/user/1").to be_accesible_for_admin}
    it { expect("/review/1/search/new").to be_accesible_for_admin}
    it { expect("/review/1/searchs/compare_records").to be_accesible_for_admin}
  end


  context "when search resources are accessed" do
    it { expect("/search/1").to be_accesible_for_admin}
    it { expect("/search/1/edit").to be_accesible_for_admin}
    it { expect("/search/1/records").to be_accesible_for_admin}
    it { expect("/search/1/references").to be_accesible_for_admin}
  end
  context "when reports are accessed" do
    it { expect("/review/1/report/PRISMA/html").to be_accesible_for_admin}
    it { expect("/review/1/report/fulltext/html").to be_accesible_for_admin}
    it { expect("/review/1/report/process/html").to be_accesible_for_admin}


  end


  context "when records are accessed" do
    it { expect("/record/1").to be_accesible_for_admin}
  end
  context "when references are acceded" do
    it {expect("/reference/19e8abd776da3d40aec0158e8ef105959bd9b57bdb5f64ce07ec3d33a0324334").to be_accesible_for_admin}
  end
  context "when canonical documents resources are accessed" do
    it { expect("/canonical_document/1").to be_accesible_for_admin}
    it { expect("/canonical_document/1/search_similar").to be_accesible_for_admin}
    it { expect("/canonical_document/1/view_doi").to be_accesible_for_admin}
  end
  context "when user resources are accessed" do
    it { expect("/user/1").to be_accesible_for_admin}
    it { expect("/user/1/messages").to be_accesible_for_admin}
    it { expect("/user/1/compose_message").to be_accesible_for_admin}
    it { expect("/user/1/change_password").to be_accesible_for_admin}
  end
  context "when tag resources are accesed" do
    it {expect("/tag/2/rs/1/cds").to be_accesible_for_admin}
    it {expect("/tag/2/rs/1/stage/screening_title_abstract/cds").to be_accesible_for_admin}
  end

  context "when dev resources are accessed" do
    it {expect("/admin/all_routes").to be_accesible_for_admin}
  end
end
require_relative 'spec_helper'

# Smoke test: preliminary test, that covers the main resources of the system.
# Just test that every page is accesible and throws an error.

describe 'Error codes for no available resources' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }

    configure_empty_sqlite
  end
  before(:each) do
    post '/login', :user=>'admin', :password=>'admin'
  end
  context "when review resources are accessed for no available review" do
    it { expect("/review/1").to responds_with_no_review_id_error(1)}
    it { expect("/review/1/edit").to responds_with_no_review_id_error(1)}
    it { expect("/review/1/canonical_documents").to responds_with_no_review_id_error(1)}
    it { expect("/review/1/repeated_canonical_documents").to responds_with_no_review_id_error(1)}

    it { expect("/review/1/searchs").to responds_with_no_review_id_error(1)}
    it { expect("/review/1/tags").to responds_with_no_review_id_error(1)}
    it { expect("/review/1/messages").to responds_with_no_review_id_error(1)}
    it { expect("/review/1/fields").to responds_with_no_review_id_error(1)}
    it { expect("/review/1/files").to responds_with_no_review_id_error(1)}
  end

  context "when review administration resources are accessed" do
    it { expect("/review/1/administration_stages").to responds_with_no_review_id_error(1)}
    it { expect("/review/1/administration/search").to responds_with_no_review_id_error(1)}
    it { expect("/review/1/administration/screening_title_abstract").to responds_with_no_review_id_error(1)}
    it { expect("/review/1/administration/screening_references").to responds_with_no_review_id_error(1)}
    it { expect("/review/1/administration/review_full_text").to responds_with_no_review_id_error(1)}
    it { expect("/review/1/administration/report").to responds_with_no_review_id_error(1)}


    it { expect("/review/1/administration/screening_title_abstract/cd_assignations").to responds_with_no_review_id_error(1)}
    it { expect("/review/1/administration/screening_title_abstract/cd_without_allocations").to responds_with_no_review_id_error(1)}
    it { expect("/review/1/stage/screening_title_abstract/complete_empty_abstract_manual").to responds_with_no_review_id_error(1)}

  end


  context "when review stages resources are accessed" do
    it { expect("/review/1/screening_title_abstract").to responds_with_no_review_id_error(1)}

    it { expect("/review/1/screening_references").to responds_with_no_review_id_error(1)}
    it { expect("/review/1/review_full_text").to responds_with_no_review_id_error(1)}

  end

  context "when user enter extract information form" do
    it { expect("/review/1/extract_information/cd/137").to responds_with_no_review_id_error(1)}
  end



  context "when review searchs resources are accessed" do
    it { expect("/review/1/searchs/user/1").to responds_with_no_review_id_error(1)}
    it { expect("/review/1/search/new").to responds_with_no_review_id_error(1)}
    it { expect("/review/1/searchs/compare_records").to responds_with_no_review_id_error(1)}
  end


  context "when search resources are accessed" do
    it { expect("/search/1").to responds_with_no_search_id_error(1)}
    it { expect("/search/1/edit").to responds_with_no_search_id_error(1)}
    it { expect("/search/1/records").to responds_with_no_search_id_error(1)}
    it { expect("/search/1/references").to responds_with_no_search_id_error(1)}
  end
  context "when reports are accessed" do
    it { expect("/review/1/report/PRISMA/html").to responds_with_no_review_id_error(1)}
    it { expect("/review/1/report/fulltext/html").to responds_with_no_review_id_error(1)}
    it { expect("/review/1/report/process/html").to responds_with_no_review_id_error(1)}


  end

  context "when canonical documents resources are accessed" do
    it { expect("/canonical_document/1").to responds_with_no_cd_id_error(1)}
    it { expect("/canonical_document/1/search_similar").to responds_with_no_cd_id_error(1)}
    it { expect("/canonical_document/1/view_doi").to responds_with_no_cd_id_error(1)}
  end
  context "when user resources are accessed" do
    it { expect("/user/1000").to responds_with_no_user_id_error(1)}
    it { expect("/user/1000/messages").to responds_with_no_user_id_error(1)}
    it { expect("/user/1000/compose_message").to responds_with_no_user_id_error(1)}
    it { expect("/user/1000/change_password").to responds_with_no_user_id_error(1)}
  end
  context "when tag resources are accesed" do
    it {expect("/tag/2/rs/1/cds").to responds_with_no_tag_id_error(2)}
    it {expect("/tag/2/rs/1/stage/screening_title_abstract/cds").to responds_with_no_tag_id_error(2)}
  end
end
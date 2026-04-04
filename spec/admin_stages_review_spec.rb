require 'spec_helper'



describe 'Stage administration with complete data' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    @temp=configure_empty_sqlite
    sr_for_report
    CanonicalDocument.insert(:id=>2, :title=>"Documento 2", :year=>2020)
    CanonicalDocument.insert(:id=>3, :title=>"Documento 3", :year=>2020)

    ['screening_title_abstract', 'screening_references', 'review_full_text'].each do |stage|

      AllocationCd.insert(:systematic_review_id=>1,
                                  :canonical_document_id=>1,
                                  :user_id=>1,
                                  :stage=> stage,
                                  :instructions=>"I #{stage}"
      )

      Resolution.insert(:systematic_review_id=>1, :canonical_document_id=>2,
                        :user_id=>2, :stage=>stage,
                        :resolution=>'yes',
                        :commentary=>'STA1')
      Resolution.insert(:systematic_review_id=>1, :canonical_document_id=>3,
                        :user_id=>2, :stage=>stage,
                        :resolution=>'no',
                        :commentary=>'STA1')
    end


    login_admin
  end
  def accept_yes
    get '/review/1/stage/screening_title_abstract/pattern/yes_0__no_2__undecided_0__ND_0/resolution/yes'
  end
  def remove_assignations
    get '/review/1/stage/screening_title_abstract/rem_assign_user/1/all'
    get '/review/1/stage/screening_title_abstract/rem_assign_user/2/all'
  end
  def res_sta
    $db["SELECT resolution,COUNT(*) as n FROM resolutions WHERE systematic_review_id=1 and stage='screening_title_abstract' GROUP BY resolution"].to_hash(:resolution)
  end
  def res_sr
    $db["SELECT resolution,COUNT(*) as n FROM resolutions WHERE systematic_review_id=1 and stage='screening_references' GROUP BY resolution"].to_hash(:resolution)
  end
  def res_rft
    $db["SELECT resolution,COUNT(*) as n FROM resolutions WHERE systematic_review_id=1 and stage='review_full_text' GROUP BY resolution"].to_hash(:resolution)
  end



  def assignations_admin
    $db["SELECT stage, COUNT(*) as n FROM allocation_cds WHERE systematic_review_id=1 and user_id=1 GROUP BY stage"].to_hash(:stage)
  end


  context "when verifying the number of resolutions per stage" do
    it "returns 2 'yes' resolutions for the STA stage" do
      expect(res_sta['yes'][:n]).to eq(2)
    end

    it "returns 1 'no' resolution for the STA stage" do
      expect(res_sta['no'][:n]).to eq(1)
    end

    it "returns 1 'yes' resolutions for the SR stage" do
      expect(res_sr['yes'][:n]).to eq(1)
    end

    it "returns 1 'no' resolutions for the SR stage" do
      expect(res_sr['no'][:n]).to eq(1)
    end

    it "returns 2 'yes' resolution for the RFT stage" do
      expect(res_rft['yes'][:n]).to eq(2)
    end

    it "returns 1 'no' resolutions for the RFT stage" do
      expect(res_rft['no'][:n]).to eq(1)
    end
  end

  context "when accept to 'yes' on 2 'no' decisions on sta" do
    before(:all) do
      accept_yes
    end
    it "should response be ok" do

      expect(last_response).to be_redirect
    end
    it "should have 2 yes resolutions" do expect(res_sta['yes'][:n]).to eq(2) end
    it "should have 1 no resolutions"   do expect(res_sta['no'][:n]).to eq(1) end
  end



  context "when check assignations on each stage" do
    it "should have 1 for admin on sta" do expect(assignations_admin['screening_title_abstract'][:n]).to eq(1) end
    it "should have 1 for admin on sr" do expect(assignations_admin['screening_references'][:n]).to eq(1) end
    it "should have 1 for admin on rft" do expect(assignations_admin['review_full_text'][:n]).to eq(1) end

  end
  context 'when add a commentary on a assignation' do
    before(:context) do
      put '/allocation/user/1/review/1/cd/1/stage/screening_title_abstract/edit_instruction', value:'new instruction'
    end
    it "should response be ok" do
      expect(last_response).to be_ok
    end

    let(:asignacion) {AllocationCd[:systematic_review_id=>1, :user_id=>1, :canonical_document_id=>1, :stage=>"screening_title_abstract"]}
    it "should create commentary on assignation object" do
      expect(asignacion[:instructions]).to eq('new instruction')
    end
  end

  context "when assign all document for admin on sta" do
    before(:context) do
      get '/review/1/stage/screening_title_abstract/add_assign_user/1/all'
    end
    it "should have 1 assignations on sta" do
      expect(assignations_admin['screening_title_abstract'][:n]).to eq(1)
    end
    it "should have 84 assignations on sta if we remove one later" do
      post '/canonical_document/user_allocation/unallocate', {rs_id:1, cd_id:64, user_id:1, stage:'screening_title_abstract'}
      expect(assignations_admin['screening_title_abstract'][:n]).to eq(1)
    end
  end

  context "when remove all assignations for admin on sta" do

    it "should have 0 assignations on sta" do
      remove_assignations
      expect(assignations_admin['screening_title_abstract']).to be_nil
    end
    it "should have 1 assignations on sta if we add one later" do
      remove_assignations
      post '/canonical_document/user_allocation/allocate', {rs_id:1, cd_id:1, user_id:1, stage:'screening_title_abstract'}
      expect(assignations_admin['screening_title_abstract'][:n]).to eq(1)
    end
  end

  context "when assign all document without previous assignation on sta" do

    before(:context) do
      remove_assignations
      post '/canonical_document/user_allocation/allocate', {rs_id:1, cd_id:64, user_id:2, stage:'screening_title_abstract'}
      get '/review/1/stage/screening_title_abstract/add_assign_user/1/without_allocation'
    end
    it "should have 1 assignations on sta" do
      expect(assignations_admin['screening_title_abstract'][:n]).to eq(1)
    end
  end

  context "when bibtex is retrieved" do
    before(:context) do
      get '/review/1/stage/report/generate_bibtex'
    end
    it "should response be ok" do expect(last_response).to be_ok end
    it "should content type be text/x-bibtex" do expect(last_response.header['Content-Type']).to include('text/x-bibtex') end
    it "should content-disposition is attachment and include .bib" do expect(last_response.header['Content-Disposition']).to match(/attachment.+\.bib/) end
  end

  context "when doi list is retrieved" do
    before(:context) do
      get '/review/1/stage/report/generate_doi_list'
    end
    it "should response be ok" do expect(last_response).to be_ok end
    it "should content type be text/plain" do expect(last_response.header['Content-Type']).to include('text/plain') end
  end

  context "when graphml is retrieved for report stage" do
    before(:context) do
      get '/review/1/stage/report/generate_graphml'
    end
    it "should response be ok" do expect(last_response).to be_ok end
    it "should content type be text/plain" do expect(last_response.header['Content-Type']).to include('application/graphml+xml') end
  end


  context "when graphml is retrieved for all canonical documents" do
    before(:context) do
      get '/review/1/generate_graphml'
    end
    it "should response be ok" do expect(last_response).to be_ok end
    it "should content type be text/plain" do expect(last_response.header['Content-Type']).to include('application/graphml+xml') end
  end

  context "when excel is retrieved for report stage" do
    before(:context) do
      get '/review/1/stage/report/generate_excel'
    end
    it "should response be ok" do expect(last_response).to be_ok end
    it "should content type be text/plain" do expect(last_response.header['Content-Type']).to include('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet') end
  end



  after(:all) do
    @temp=nil
  end
end
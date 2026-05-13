require 'spec_helper'
require 'tempfile'



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

  def build_assignations_xlsx(rows)
    require 'caxlsx'
    tempfile=Tempfile.new(['assignations_import', '.xlsx'])
    tempfile.close

    package=Axlsx::Package.new
    package.workbook.add_worksheet(:name => 'assignations') do |sheet|
      sheet.add_row ["id", "reference", "[1] Administrator", "[2] Analyst"]
      rows.each do |row|
        sheet.add_row [
          row[:id],
          row[:reference],
          row[:admin],
          row[:analyst]
        ]
      end
    end
    package.serialize(tempfile.path)
    tempfile
  end


  context "when viewing the stage administration index" do
    before(:context) do
      get '/review/1/administration_stages'
    end
    it "should response be ok" do expect(last_response).to be_ok end
    it "should include a link to a current review stage" do
      expect(last_response.body).to include('/review/1/administration/search')
    end
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

  context "when resolving a pattern with documents already resolved" do
    before(:all) do
      get '/review/1/stage/screening_title_abstract/pattern/yes_0__no_0__undecided_0__ND_0/resolution/yes'
    end
    it "should not overwrite previous yes resolutions" do expect(res_sta['yes'][:n]).to eq(2) end
    it "should not overwrite previous no resolutions"   do expect(res_sta['no'][:n]).to eq(1) end
  end

  context "when viewing stage administration" do
    before(:all) do
      get '/review/1/administration/screening_title_abstract'
    end
    it "should response be ok" do expect(last_response).to be_ok end
    it "should show disabled controls for resolved patterns" do expect(last_response.body).to include("All documents resolved") end
  end

  context "when viewing full text administration" do
    before(:context) do
      get '/review/1/administration/review_full_text'
    end
    it "should response be ok" do expect(last_response).to be_ok end
    it "should link to the canonical document status endpoint" do
      expect(last_response.body).to include('/review/1/administration/review_full_text/canonical_document_status')
    end
    it "should not render the canonical document status table inline" do
      expect(last_response.body).not_to include('Reported by users')
    end
  end

  context "when viewing canonical document file status for full text" do
    before(:context) do
      DocumentReport.where(
        systematic_review_id:1,
        canonical_document_id:1,
        report_type:DocumentReport::MISSING_FILE
      ).delete
      DocumentReport.create(systematic_review_id:1, canonical_document_id:1, user_id:1, report_type:DocumentReport::MISSING_FILE)
      DocumentReport.create(systematic_review_id:1, canonical_document_id:1, user_id:2, report_type:DocumentReport::MISSING_FILE)
      get '/review/1/administration/review_full_text/canonical_document_status'
    end
    it "should response be ok" do expect(last_response).to be_ok end
    it "should keep the administration breadcrumb" do
      expect(last_response.body).to include('/review/1/administration/review_full_text')
    end
    it "should show missing file reports by users" do
      expect(last_response.body).to include('Reported by users')
      expect(last_response.body).to include('Missing file')
      expect(last_response.body).to include('>2</td>')
    end
  end

  context "when viewing the canonical documents for a decision pattern" do
    before(:context) do
      get '/review/1/stage/screening_title_abstract/pattern/yes_0__no_0__undecided_0__ND_1/view'
    end
    it "should response be ok" do expect(last_response).to be_ok end
    it "should include the toggle resolved control" do
      expect(last_response.body).to include('toggle-resolved')
    end
    it "should include personal favorite and report controls for the session user" do
      expect(last_response.body).to include('favorite-cd-1-user-1')
      expect(last_response.body).to include('/favorite/user/1/canonical_document/1/add')
      expect(last_response.body).to include('document-report-1-1-1')
      expect(last_response.body).to include('/review/1/document_report/cd/1/user/1/report_types')
    end
  end

  context "when viewing the import and export decisions page" do
    before(:context) do
      get '/review/1/stage/screening_title_abstract/import_export_decisions'
    end
    it "should response be ok" do expect(last_response).to be_ok end
    it "should include the export decisions action" do
      expect(last_response.body).to include('/review/1/stage/screening_title_abstract/export_decisions_excel')
    end
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

  context "when viewing canonical document assignations" do
    before(:context) do
      get '/review/1/administration/screening_title_abstract/cd_assignations'
    end
    it "should response be ok" do expect(last_response).to be_ok end
    it "should include the excel export action" do
      expect(last_response.body).to include('/review/1/administration/screening_title_abstract/cd_assignations_excel/save')
    end
  end

  context "when viewing canonical documents without assignations" do
    before(:context) do
      AllocationCd.where(:systematic_review_id=>1, :canonical_document_id=>1,
                         :stage=>'screening_title_abstract').delete
      get '/review/1/administration/screening_title_abstract/cd_without_allocations'
    end
    it "should response be ok" do expect(last_response).to be_ok end
    it "should use the without allocation batch action" do
      expect(last_response.body).to include('/review/1/stage/screening_title_abstract/add_assign_user/1/without_allocation')
    end
  end

  context "when cd assignations are exported to excel" do
    ['save', 'save_only_not_allocated', 'save_only_not_resolved'].each do |mode|
      context "with #{mode} mode" do
        before(:context) do
          get "/review/1/administration/screening_title_abstract/cd_assignations_excel/#{mode}"
        end

        it "should response be ok" do expect(last_response).to be_ok end
        it "should content type be correct mimetype" do
          expect(last_response.header['Content-Type']).to eq('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
        end
        it "should content-disposition include the assignation workbook name" do
          expect(last_response.header['Content-Disposition']).to include('cd_assignation_1_screening_title_abstract.xlsx')
        end
      end
    end
  end

  context "when cd assignations are imported from excel" do
    before(:context) do
      AllocationCd.where(:systematic_review_id=>1, :canonical_document_id=>2,
                         :user_id=>1, :stage=>'screening_title_abstract').delete
      @assignations_xlsx=build_assignations_xlsx([
        {id: 2, reference: 'Documento 2', admin: 1, analyst: 0}
      ])
      uploaded_file=Rack::Test::UploadedFile.new(@assignations_xlsx.path, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", true)
      post '/review/1/administration/screening_title_abstract/cd_assignations_excel/load',
           {file: uploaded_file},
           'HTTP_REFERER' => '/review/1/administration/screening_title_abstract/cd_assignations'
    end

    after(:context) do
      @assignations_xlsx.unlink if @assignations_xlsx
    end

    it "should response be redirect" do expect(last_response).to be_redirect end
    it "should create the assignation from the workbook" do
      assignation=AllocationCd[:systematic_review_id=>1, :canonical_document_id=>2,
                               :user_id=>1, :stage=>'screening_title_abstract']
      expect(assignation).to_not be_nil
    end
  end

  context "when viewing user reassignations" do
    before(:context) do
      CanonicalDocument.insert(:id=>4, :title=>"Documento 4", :year=>2021) unless CanonicalDocument[4]
      create_record(id:[4], cd_id:[4], search_id:[[1]]) unless Record[4]
      Resolution.where(:systematic_review_id=>1, :canonical_document_id=>4,
                       :stage=>'screening_title_abstract').delete
      AllocationCd.where(:systematic_review_id=>1, :canonical_document_id=>4,
                         :stage=>'screening_title_abstract').delete
      AllocationCd.insert(:systematic_review_id=>1, :canonical_document_id=>4,
                          :user_id=>1, :stage=>'screening_title_abstract')
      get '/review/1/stage/screening_title_abstract/reassign_user/1'
    end
    it "should response be ok" do expect(last_response).to be_ok end
    it "should include the assigned canonical document" do
      expect(last_response.body).to include('Documento 4')
    end
  end

  context "when reassigning canonical documents to another user" do
    before(:context) do
      CanonicalDocument.insert(:id=>5, :title=>"Documento 5", :year=>2021) unless CanonicalDocument[5]
      create_record(id:[5], cd_id:[5], search_id:[[1]]) unless Record[5]
      Resolution.where(:systematic_review_id=>1, :canonical_document_id=>5,
                       :stage=>'screening_title_abstract').delete
      AllocationCd.where(:systematic_review_id=>1, :canonical_document_id=>5,
                         :stage=>'screening_title_abstract').delete
      AllocationCd.insert(:systematic_review_id=>1, :canonical_document_id=>5,
                          :user_id=>1, :stage=>'screening_title_abstract')
      post '/review/reassign_cd_to_user',
           {review_id: 1, user_id_from: 1, user_id_to: 2,
            stage: 'screening_title_abstract',
            canonical_documents: {'5' => 'on'}},
           'HTTP_REFERER' => '/review/1/stage/screening_title_abstract/reassign_user/1'
    end
    it "should response be redirect" do expect(last_response).to be_redirect end
    it "should move the assignation to the target user" do
      expect(AllocationCd[:systematic_review_id=>1, :canonical_document_id=>5,
                          :user_id=>1, :stage=>'screening_title_abstract']).to be_nil
      expect(AllocationCd[:systematic_review_id=>1, :canonical_document_id=>5,
                          :user_id=>2, :stage=>'screening_title_abstract']).to_not be_nil
    end
  end

  context "when reassigning without selecting canonical documents" do
    before(:context) do
      post '/review/reassign_cd_to_user',
           {review_id: 1, user_id_from: 1, user_id_to: 2,
            stage: 'screening_title_abstract'}
    end
    it "should response be redirect" do expect(last_response).to be_redirect end
    it "should redirect back to the reassignation page" do
      expect(last_response.location).to include('/review/1/stage/screening_title_abstract/reassign_user/1')
    end
  end

  context "when viewing documents with empty abstracts" do
    before(:context) do
      CanonicalDocument[1].update(:abstract=>nil)
      get '/review/1/stage/review_full_text/complete_empty_abstract_manual'
    end
    it "should response be ok" do expect(last_response).to be_ok end
    it "should include the canonical document without abstract" do
      expect(last_response.body).to include('Title 1')
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

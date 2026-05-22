require 'spec_helper'

describe 'Canonical Document merging' do


  shared_examples 'correct merge' do
    let(:cd) {CanonicalDocument[1]}

    it "should retain 2 canonical document" do
      expect(CanonicalDocument.count).to eq(2)
    end
    it "should canonical document retained equal to first listed" do
      expect(cd).to be_truthy
    end
    it "should canonical document retained have correct title" do
      expect(cd[:title]).to eq("Title 1")
    end
    it "should canonical document retained have correct year" do
      expect(cd[:year]).to eq(2000)
    end
    it "should canonical document retained have correct author" do
      expect(cd[:author]).to eq('author_1')
    end
    it "should canonical document retained have correct doi" do
      expect(cd[:doi]).to eq("1234")
    end
    it "should canonical document retained have correct pmid" do
      expect(cd[:pmid]).to eq("1")
    end
    it "should canonical document retained have correct journal" do
      expect(cd[:journal]).to eq("J1")
    end
    it "should record_searches will be correct" do
      expect(RecordsSearch.where(:search_id=>1).map{|v| v[:record_id]}).to eq([1,2,3,4])
    end
    it "should records all link to correct canonical_document" do
      expect(Record.where(:id=>[1,2,3]).map{|v| v[:canonical_document_id]}).to eq([1,1,1])
    end
  end


  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    @temp=configure_empty_sqlite
    login_admin
  end

  def pre_context
    create_sr
    @sr1=SystematicReview[1]
    @sr1.stage='report'
    CanonicalDocument.insert(:id=>1, :title=>"Title 1", :year=>0, :author=>'author_1', :doi=>nil)
    CanonicalDocument.insert(:id=>2, :title=>"Title 2", :year=>2000, :pmid=>1, :doi=>1234)
    CanonicalDocument.insert(:id=>3, :title=>"Title 3", :year=>0, :journal=>"J1", :doi=>nil)
    CanonicalDocument.insert(:id=>4, :title=>"Title 4", :year=>0, :journal=>"J2", :doi=>nil)

    create_search
    Search[1].update(valid:true)
    create_record(n:4, search_id:[1,1,1,1], cd_id:[1,2,3,nil])

    1.upto(4) do |cd_id|
      Resolution.insert(:systematic_review_id=>1, :canonical_document_id=>cd_id, :user_id=>1, :stage=>'screening_title_abstract', :resolution=>'yes')
      Resolution.insert(:systematic_review_id=>1, :canonical_document_id=>cd_id, :user_id=>1, :stage=>'review_full_text', :resolution=>'yes')
    end

    # TODO: Add extra fields to compare
  end

  def after_context
    $db[:file_extraction_informations].delete if $db.table_exists?(:file_extraction_informations)
    $db[:file_srs].delete
    $db[:file_cds].delete
    $db[:files].delete
    $db[:sr_document_reports].delete
    $db[:records_searches].delete
    $db[:searches].delete
    $db[:records].delete
    $db[:decisions].delete
    $db[:resolutions].delete
    $db[:canonical_documents].delete
    $db[:systematic_reviews].delete

  end

  context "when canonical document merge rules are checked" do
    it "should not have pending rules for current schema" do
      expect(Buhos::CanonicalDocumentMerger.missing_merge_rules).to eq({})
    end

    it "should detect a table without merge rule" do
      $db.create_table(:pending_cd_merge_rule) do
        primary_key :id
        foreign_key :canonical_document_id, :canonical_documents, :null => false, :key => [:id]
      end

      expect(Buhos::CanonicalDocumentMerger.missing_merge_rules).to eq(
        pending_cd_merge_rule: [:canonical_document_id]
      )
    ensure
      $db.drop_table?(:pending_cd_merge_rule)
    end
  end

  context "when /canonical_document/actions is used" do
    before(:context) do
      pre_context
      post '/canonical_document/actions', :action=>'merge', :canonical_document=>{"1"=>'yes',"2"=>'yes',"3"=>'yes'}
      #@lr=last_response
    end

    it "a redirect back" do
      expect(last_response).to be_redirect
    end
    it_behaves_like 'correct merge'


    after(:context) do
      after_context
    end
  end

  context "when Buhos::CanonicalDocumentMerger.merge is used" do
    before(:context) do
      pre_context
      Buhos::CanonicalDocumentMerger.merge([1,2,3])
    end
    it_behaves_like 'correct merge'

    after(:context) do
      after_context
    end
  end

  context "when merging contradictory decisions from the same user and stage" do
    before(:context) do
      pre_context
      Decision.insert(:systematic_review_id=>1, :canonical_document_id=>1, :user_id=>1,
                      :stage=>'screening_title_abstract', :decision=>'yes')
      Decision.insert(:systematic_review_id=>1, :canonical_document_id=>2, :user_id=>1,
                      :stage=>'screening_title_abstract', :decision=>'no')
      Buhos::CanonicalDocumentMerger.merge([1,2])
    end

    it "should leave the merged decision as undecided" do
      decision=Decision[:systematic_review_id=>1, :canonical_document_id=>1, :user_id=>1,
                        :stage=>'screening_title_abstract']
      expect(decision[:decision]).to eq('undecided')
    end

    after(:context) do
      after_context
    end
  end

  context "when merging contradictory resolutions" do
    before(:context) do
      pre_context
      Resolution.where(:systematic_review_id=>1, :canonical_document_id=>2,
                       :stage=>'screening_title_abstract').update(:resolution=>'no')
      Buhos::CanonicalDocumentMerger.merge([1,2])
    end

    it "should delete the conflicting resolution" do
      expect(Resolution.where(:systematic_review_id=>1, :canonical_document_id=>1,
                              :stage=>'screening_title_abstract').count).to eq(0)
    end

    it "should create a conflicting resolution report" do
      report=DocumentReport[:systematic_review_id=>1, :canonical_document_id=>1, :user_id=>1,
                            :report_type=>'conflicting_resolution']
      expect(report).to be_truthy
      expect(report[:status]).to eq('pending')
    end

    it "should resolve the report when a resolution is defined" do
      Resolution.set_for_document(systematic_review_id:1, canonical_document_id:1,
                                  stage:'screening_title_abstract', resolution:'yes',
                                  user_id:1)
      report=DocumentReport[:systematic_review_id=>1, :canonical_document_id=>1, :user_id=>1,
                            :report_type=>'conflicting_resolution']
      expect(report[:status]).to eq('resolved')
    end

    after(:context) do
      after_context
    end
  end

  context "when merging resolved and unresolved resolutions" do
    before(:context) do
      pre_context
      Resolution.where(:systematic_review_id=>1, :canonical_document_id=>2,
                       :stage=>'screening_title_abstract').update(:resolution=>Resolution::NO_RESOLUTION)
      Buhos::CanonicalDocumentMerger.merge([1,2])
    end

    it "should keep the definitive resolution" do
      resolution=Resolution[:systematic_review_id=>1, :canonical_document_id=>1,
                            :stage=>'screening_title_abstract']
      expect(resolution[:resolution]).to eq('yes')
    end

    it "should not create a conflicting resolution report" do
      expect(DocumentReport.where(:systematic_review_id=>1, :canonical_document_id=>1,
                                  :report_type=>'conflicting_resolution').count).to eq(0)
    end

    after(:context) do
      after_context
    end
  end

  context "when merging documents with extraction guideline files" do
    before(:context) do
      pre_context
      file_id_1=IFile.insert(:filename=>'guideline_1.txt', :filetype=>'text/plain', :sha256=>'guideline_1')
      file_id_2=IFile.insert(:filename=>'guideline_2.txt', :filetype=>'text/plain', :sha256=>'guideline_2')
      @file_ids=[file_id_1, file_id_2].sort
      FileExtractionInformation.insert(:file_id=>file_id_1, :systematic_review_id=>1,
                                       :canonical_document_id=>1, :user_id=>1)
      FileExtractionInformation.insert(:file_id=>file_id_2, :systematic_review_id=>1,
                                       :canonical_document_id=>2, :user_id=>1)
      Buhos::CanonicalDocumentMerger.merge([1,2])
    end

    it "should keep all extraction guideline files on the retained document" do
      expect(FileExtractionInformation.where(:canonical_document_id=>1).map(:file_id).sort).to eq(@file_ids)
    end

    after(:context) do
      after_context
    end
  end

  context "when Buhos::CanonicalDocumentMerger.merge is used with different order" do
    let(:cd) {CanonicalDocument[2]}
    before(:context) do
      pre_context
      Buhos::CanonicalDocumentMerger.merge([2,3,1])
    end
    it "should canonical document retained equal to first listed" do
      expect(cd).to be_truthy
    end
    after(:context) do
      after_context
    end

  end



  context "when /review/1/canonical_document/automatic_deduplication/doi is used" do

    before(:context) do
      pre_context
      CanonicalDocument.where(:id=>[1,2,3]).update(:doi=>"1234")
      post "/review/1/canonical_document/automatic_deduplication/doi"
    end
    it_behaves_like 'correct merge'

    after(:context) do
      after_context
    end

  end

  context "when /review/1/canonical_document/automatic_deduplication/scopus is used" do

    before(:context) do
      pre_context
      CanonicalDocument.where(:id=>[1,2,3]).update(:scopus_id=>"2-s2.23")
      post "/review/1/canonical_document/automatic_deduplication/scopus"
    end
    it_behaves_like 'correct merge'

    after(:context) do
      after_context
    end

  end

  context "when /review/1/canonical_document/automatic_deduplication/wos is used" do

    before(:context) do
      pre_context
      CanonicalDocument.where(:id=>[1,2,3]).update(:wos_id=>"WOS:123456")
      post "/review/1/canonical_document/automatic_deduplication/wos"
    end
    it_behaves_like 'correct merge'

    after(:context) do
      after_context
    end

  end

  context "when /review/1/canonical_document/automatic_deduplication/scielo is used" do

    before(:context) do
      pre_context
      CanonicalDocument.where(:id=>[1,2,3]).update(:scielo_id=>"SCIELO:234")
      post "/review/1/canonical_document/automatic_deduplication/scielo"
    end
    it_behaves_like 'correct merge'

    after(:context) do
      after_context
    end

  end


  context "when /review/1/canonical_document/automatic_deduplication/pubmed is used" do

    before(:context) do
      pre_context
      CanonicalDocument.where(:id=>[1,2,3]).update(:pubmed_id=>"12345")
      post "/review/1/canonical_document/automatic_deduplication/pubmed"
    end
    it_behaves_like 'correct merge'

    after(:context) do
      after_context
    end

  end
  context "when /canonical_document/merge is used using doi" do

    before(:context) do
      pre_context
      CanonicalDocument.where(:id=>[1,2,3]).update(:doi=>"1234")
      post "/canonical_document/merge", :doi=>"1234", :pk_ids=>"1,2,3"
    end
    it_behaves_like 'correct merge'

    after(:context) do
      after_context
    end
  end

  context "when /canonical_document/merge is used using pk" do

    before(:context) do
      pre_context
      CanonicalDocument.where(:id=>[1,2]).update(:doi=>nil)
      CanonicalDocument.where(:id=>[3]).update(:doi=>"1234")
      post "/canonical_document/merge", :pk_ids=>"1,2,3"
    end
    it_behaves_like 'correct merge'

    after(:context) do
      after_context
    end

  end


end

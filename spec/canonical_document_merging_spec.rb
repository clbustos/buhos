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
    $db[:records_searches].delete
    $db[:searches].delete
    $db[:records].delete
    $db[:resolutions].delete
    $db[:canonical_documents].delete
    $db[:systematic_reviews].delete

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

  context "when CanonicalDocument.merge is used" do
    before(:context) do
      pre_context
      CanonicalDocument.merge([1,2,3])
    end
    it_behaves_like 'correct merge'

    after(:context) do
      after_context
    end
  end

  context "when CanonicalDocument.merge is used with different order" do
    let(:cd) {CanonicalDocument[2]}
    before(:context) do
      pre_context
      CanonicalDocument.merge([2,3,1])
    end
    it "should canonical document retained equal to first listed" do
      expect(cd).to be_truthy
    end
    after(:context) do
      after_context
    end

  end



  context "when /review/1/automatic_deduplication is used" do

    before(:context) do
      pre_context
      CanonicalDocument.where(:id=>[1,2,3]).update(:doi=>"1234")
      post "/review/1/automatic_deduplication"
    end
    it_behaves_like 'correct merge'

    after(:context) do
      after_context
    end

  end

  context "when /canonical_document/merge is used usign doi" do

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

  context "when /canonical_document/merge is used usign doi" do

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
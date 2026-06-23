require 'spec_helper'

describe 'Prisma Report' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    @temp=configure_empty_database
    SystematicReview.insert(:name=>'Test Review', :group_id=>1, :sr_administrator=>1)
    login_admin
  end
  context "when svg PRISMA flow diagram is downloaded" do
    before(:context) do
      get '/review/1/report/PRISMA/svg_download'
    end
    it "should response be ok" do expect(last_response).to be_ok end
    it "should content type be image/svg+xml" do expect(last_response.header['Content-Type']).to eq('image/svg+xml') end
    it "should content dispostion be attachment and include .svg on name" do
      expect(last_response.header['Content-Disposition']).to include("attachment") and
          expect(last_response.header['Content-Disposition']).to include(".svg")
    end

  end

  context "when review hides tags from other users" do
    before(:context) do
      @review=SystematicReview[1]
      @previous_visibility=@review[:show_other_users_tags]
      @review.update(:show_other_users_tags=>false)
      @tag=Tag.get_tag('ex:Excluded by other reviewer')
      CanonicalDocument.insert(:id=>2, :title=>'Rejected full text', :year=>0)
      create_search(:id=>[1])
      create_record(:id=>[2], :cd_id=>[2], :search_id=>[[1]])
      TagInCd.approve_tag(CanonicalDocument[2], @review, @tag, 2)
      Resolution.insert(:systematic_review_id=>1,
                        :canonical_document_id=>2,
                        :user_id=>1,
                        :stage=>'screening_title_abstract',
                        :resolution=>'yes')
      Resolution.insert(:systematic_review_id=>1,
                        :canonical_document_id=>2,
                        :user_id=>1,
                        :stage=>'review_full_text',
                        :resolution=>'no')
    end

    it "keeps all exclusion tags visible in the PRISMA report" do
      report=ReportBuilder::PrismaReport.new(@review, Sinatra::Application)
      report.process_information
      expect(report.instance_variable_get(:@reason_to_exclude_count)).to include("Excluded by other reviewer"=>1)
    end

    after(:context) do
      @review.update(:show_other_users_tags=>@previous_visibility)
      Resolution.where(:canonical_document_id=>2).delete
      RecordsSearch.where(:record_id=>2).delete
      Record[2].delete
      Search[1].delete
      TagInCd.where(:tag_id=>@tag.id).delete
      @tag.delete_if_unused
      CanonicalDocument[2].delete
    end
  end

end

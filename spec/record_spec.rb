require 'spec_helper'

describe 'Record' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    @temp=configure_empty_sqlite
    sr_references
    login_admin
  end
  let(:reference) {Record[1]}
  context "#crossref_query result" do
    let(:crossref_query) {Record[1].crossref_query}
    it {
      expect(crossref_query).to be_a(Array)
    }
    it "every element should have a doi" do
      expect(crossref_query.all? {|v| v.keys.include?('doi')}).to be true
    end
  end

  context "#references_id" do
    it "should retrieve 3 references" do
      expect(Record[1].references_id.count).to eq(3)
    end
  end

  context "#add_doi_automatic result on a reference with doi and canonical with doi" do

    let(:result) {Record[1].add_doi_automatic}
    it {
      expect(result).to be_a(::Result)
    }
    it "nothing to do" do
      expect(result.events[0][:message]).to eq(I18n::t("record.doi_already_added_to", record_title: Record[1][:title]))
    end
  end

  context "#add_doi_automatic result on a reference with doi, but canonical without it" do
    before(:each) do
      @canonical_id=Record[1].canonical_document_id
      CanonicalDocument[@canonical_id].update(:doi=>nil)
      @result=Record[1].add_doi_automatic
    end

    it {
      expect(@result).to be_a(::Result)
    }
    let(:cd) {CanonicalDocument[@canonical_id]}
    it "should add doi to canonical document" do
      expect(cd[:doi]).to eq(Record[1].doi)
    end

    it "should send a message that doi is already added on record" do
      expect(@result.events[0][:message]).to eq(I18n::t("record.already_added_doi", doi:Record[1].doi, record_id:1))
    end
    it "should send a message that doi is assigned to canonical document" do
      expect(@result.events[1][:message]).to eq(I18n::t("record.assigned_doi_to_cd", doi:Record[1].doi, cd_title:cd[:title]))
    end

  end

  context "#references_automatic_crossref" do
    before(:context) do
      references=RecordsReferences.where(record_id:1).map(:reference_id)

      references_in=references.map{|v| "'#{v}'"}.join(',')

      $db.run("DELETE FROM records_references WHERE record_id=1")
      $db.run("DELETE FROM records_references WHERE reference_id IN (#{references_in})")
      $db.run("DELETE FROM bib_references WHERE id IN (#{references_in})")

      @result=Record[1].references_automatic_crossref
    end
    it {
      expect(@result).to be_a(::Result)
    }
    it "should process 50 references" do
      expect(@result.events[0][:message]).to include("50")
    end
    it "record should have now 50 references" do
      expect(RecordsReferences.where(record_id:1).count).to eq(50)
    end
  end


end
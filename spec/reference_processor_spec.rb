require 'spec_helper'

describe 'ReferenceProcessor' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    @temp=configure_empty_database
    1.upto(30) do |i|
      doi="10.1000/reference-#{i}"
      CanonicalDocument.insert(:id=>i, :title=>"Reference processor document #{i}", :doi=>doi, :year=>2020)
      Reference.get_by_text_and_doi("Reference #{i}. DOI #{doi}", doi, true).
        update(:canonical_document_id=>i)
    end
  end
  context "when reference processor is used" do
    it "should add doi and canonical document to references without them, if possible" do
      references=$db["SELECT * FROM bib_references WHERE doi IS NOT NULL AND canonical_document_id IS NOT NULL"].map(:id)[0...30]
      Reference.where(:id=>references).update(:canonical_document_id=>nil, :doi=>nil)
      references.each do |ref_id|
        rp=ReferenceProcessor.new(Reference[ref_id])
        expect(rp.process_doi).to be true
      end
      expect(Reference.where(:id=>references).exclude(:doi=>nil, :canonical_document_id=>nil).count).to eq(30)
    end
  end
end

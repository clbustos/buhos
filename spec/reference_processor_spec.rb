require 'spec_helper'

describe 'ReferenceProcessor' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    @temp=configure_complete_sqlite
  end
  context "when reference processor is used" do
    it "should add doi and canonical document to references without them, if possible" do
      references=$db["SELECT * FROM referencias WHERE doi IS NOT NULL AND canonico_documento_id IS NOT NULL"].map(:id)[0...30]
      Referencia.where(:id=>references).update(:canonico_documento_id=>nil, :doi=>nil)
      references.each do |ref_id|
        rp=ReferenceProcessor.new(Referencia[ref_id])
        expect(rp.process_doi).to be true
      end
      expect(Referencia.where(:id=>references).exclude(:doi=>nil, :canonico_documento_id=>nil).count).to eq(30)
    end
  end
end
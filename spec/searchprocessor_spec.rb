require 'spec_helper'

describe 'SearchProcessor' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    @temp=configure_complete_sqlite

  end
  context "when smoke test is applied" do
    let(:searchs) {Busqueda.where(:revision_sistematica_id=>1)}
    it "works on each search" do
      searchs.each do |search|
        sp=SearchProcessor.new(search)
        expect(sp.result.success?).to be true
      end
    end
  end
end
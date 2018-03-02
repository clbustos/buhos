require 'spec_helper'

describe 'SearchProcessor' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    @temp=configure_complete_sqlite

  end
  context "when smoke test is applied" do
    let(:searches) {Search.where(:systematic_review_id=>1)}
    it "works on each search" do
      searches.each do |search|
        sp=SearchProcessor.new(search)
        expect(sp.result.success?).to be true
      end
    end
  end
end
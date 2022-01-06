require 'spec_helper'

describe 'Search Validator' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    @temp=configure_empty_sqlite
    create_sr(n:3)

    CanonicalDocument.insert(:id=>1,:title=>nil, :author=>nil, :abstract=>nil, :year=>0)
    CanonicalDocument.insert(:id=>2,:title=>'Title', :author=>'Author', :abstract=>"Abstract",:year=>2000)
    CanonicalDocument.insert(:id=>3,:title=>'Title 2', :author=>'Author 2', :abstract=>"Abstract 2",:year=>2000)

    create_search(:n=>3, :systematic_review_id=>(1..3).to_a)
    create_record(:n=>4, :cd_id=>[nil, 1,2,3], :search_id=>[1,1,[1,3],3])
    login_admin
  end
  let(:sv) {SearchValidatorUser.new(SystematicReview[1], User[1])}
  let(:sv2) {SearchValidatorUser.new(SystematicReview[2], User[1])}
  let(:sv3) {SearchValidatorUser.new(SystematicReview[3], User[1])}
  let(:sv4) {SearchValidatorUser.new(SystematicReview[3], User[2])}
  it "should be initialized correctly" do
    expect(sv).to be_a(SearchValidatorUser)
  end

  context "on invalid records" do

    before do
      sv.validate
    end
    after do
      Search[1].update(:valid=>nil)
    end
    it ".valid should be false" do
      expect(sv.valid).to be false
    end
    it ".invalid_records should be correct" do
      expect(sv.invalid_records.map {|r| r.id}).to eq [1,2]
    end

    it ".valid_records should be correct" do
      expect(sv.valid_records.map {|r| r.id}).to eq [3]
    end
    it ".valid_records_n should be correct" do
      expect(sv.valid_records_n).to eq 1
    end
    it ".invalid_records_n should be correct" do
      expect(sv.invalid_records_n).to eq 2
    end
    it "search object should be nil" do
      expect(Search[1].valid).to be nil
    end
    it "should maintain manual search change" do
      expect(Search[1].valid).to be nil
      Search[1].update(valid:true)
      sv.validate
      expect(Search[1].valid).to be true
    end

  end
  context "on empty search" do
    before do
      sv2.validate
    end
    it ".valid should be false" do
      expect(sv2.valid).to be false
    end
    it "search object should be nil" do
      expect(Search[2].valid).to be nil
    end

  end

  context "on valid records" do
    before do
      sv3.validate
    end
    it ".valid should be true" do
      expect(sv3.valid).to be true
    end
    it ".invalid_records should be correct" do
      expect(sv3.invalid_records.map {|r| r.id}).to eq []
    end

    it ".valid_records should be correct" do
      expect(sv3.valid_records.map {|r| r.id}).to eq [3,4]
    end
    it ".valid_records_n should be correct" do
      expect(sv3.valid_records_n).to eq 2
    end
    it ".invalid_records_n should be correct" do
      expect(sv3.invalid_records_n).to eq 0
    end
    it "search object should be valid" do
      expect(Search[3].valid).to be true
    end
  end

  context "on valid records on user without searchs" do
    before do
      sv4.validate
    end
    it ".valid should be true" do
      expect(sv4.valid).to be true
    end
    it ".invalid_records should be correct" do
      expect(sv4.invalid_records.map {|r| r.id}).to eq []
    end

    it ".valid_records should be correct" do
      expect(sv4.valid_records.map {|r| r.id}).to eq []
    end
    it ".valid_records_n should be correct" do
      expect(sv4.valid_records_n).to eq 0
    end
    it ".invalid_records_n should be correct" do
      expect(sv4.invalid_records_n).to eq 0
    end
    it "search object should be valid" do
      expect(Search[1].valid).to be nil
      expect(Search[2].valid).to be nil
      expect(Search[3].valid).to be true
    end
  end



end
require 'spec_helper'
require 'json'
require_relative "../lib/semantic_scholar"

describe 'SemanticScholar' do
  before(:all) do
    @doi_list=['10.1093/nar/gks1195']
    @ss=::SemanticScholar::Remote.new()
  end

  it "should retrieve correct information for articles" do
    @doi_list.each do |doi|
      res=@ss.json_by_id(doi, :doi)
      json = JSON.parse(res)
      expect(json['paperId']).not_to be_nil
      expect(json['year']).not_to be_nil
      expect(json['abstract']).not_to be_nil
      expect(json['title']).not_to be_nil
    end

  end

  it "should return error for non a non-correct doi" do
    expect {@ss.json_by_id("NULL", "doi")}.to raise_error(Buhos::SemanticScholarError)


  end

end
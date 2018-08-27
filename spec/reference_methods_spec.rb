require 'spec_helper'
require_relative '../lib/reference_methods'
describe 'ReferenceMethods mixin' do
  before do
    @fake_cd=Object.new
    @fake_cd.extend ReferenceMethods
  end
  it ".authors_apa_6 should retrieve correct authors if defined" do
    def @fake_cd.author; "SN1, FN1 and SN2, FN2 "; end
    expect(@fake_cd.authors_apa_6).to eq("SN1, FN1, & SN2, FN2")
  end
  it ".authors_apa_6 should retrieve '--NA--' if author is nil" do
    def @fake_cd.author; nil; end
    expect(@fake_cd.authors_apa_6).to eq("--NA--")
  end

  it ".cite_apa_6 should retrieve empty data if no information is given" do
    def @fake_cd.author; nil; end
    def @fake_cd.year; 0; end
    def @fake_cd.title; nil; end
    expect(@fake_cd.cite_apa_6).to eq("(--NA--, 0)")


  end

end

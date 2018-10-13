require 'spec_helper'
require_relative '../lib/reference_methods'
describe 'ReferenceMethods mixin' do
  before do
    @fake_cd=Object.new
    @fake_cd.extend ReferenceMethods
  end

  describe '#authors_apa_6' do

    it "should retrieve correct authors names using commas (n<7)" do
      def @fake_cd.author; "SN1,    FN1 FN1b and SN2, FN2 "; end
      expect(@fake_cd.authors_apa_6).to eq("SN1, F.F., & SN2, F.")
    end
    it "should retrieve correct authors using only surnames" do
      def @fake_cd.author; "SN1 and SN2"; end
      expect(@fake_cd.authors_apa_6).to eq("SN1, & SN2")
    end

    it "should retrieve correct authors names without using commas (n<7)" do
      def @fake_cd.author; "FN1 SN1 and FN2 SN2"; end
      expect(@fake_cd.authors_apa_6).to eq("SN1, F., & SN2, F.")
    end

    it "should retrieve correct authors names (n>=7)" do
      def @fake_cd.author; 1.upto(10).map {|v| "SN#{v}, FN#{v}"}.join(" and "); end
      expect(@fake_cd.authors_apa_6).to eq("SN1, F., SN2, F., SN3, F., SN4, F., SN5, F., ..., SN10, F.")
    end


    it "should retrieve '--NA--' if author is nil" do
      def @fake_cd.author; nil; end
      expect(@fake_cd.authors_apa_6).to eq("--NA--")
    end
    it "should retrieve '--NA--' if author is ','" do
      def @fake_cd.author; '  ,  and  ,  '; end
      expect(@fake_cd.authors_apa_6).to eq("--NA--")
    end

  end
  it "#cite_apa_6 should retrieve empty data if no information is given" do
    def @fake_cd.author; nil; end
    def @fake_cd.year; 0; end
    def @fake_cd.title; nil; end
    expect(@fake_cd.cite_apa_6).to eq("(--NA--, 0)")


  end

end

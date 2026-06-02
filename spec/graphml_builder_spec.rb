require 'spec_helper'

describe 'Buhos::GraphML_Builder' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    @temp=configure_empty_database
    create_stage_dataset
  end
  context 'when report stage is processed' do
    let(:graph) {Buhos::GraphML_Builder.new(SystematicReview[1],'report')}
    let(:xml) {Nokogiri::XML(graph.generate_graphml) }
    it "should parse with Nokogiri" do
      #$log.info(graph.generate_graphml)
      expect {Nokogiri::XML(graph.generate_graphml) }.to_not raise_error
    end
    it "should have one node per document" do
      expect(xml.xpath("//xmlns:node").length).to eq(2)
    end
  end

  context 'when all stages are processed' do
    let(:graph) {Buhos::GraphML_Builder.new(SystematicReview[1],nil)}
    let(:xml) {Nokogiri::XML(graph.generate_graphml) }
    it "should parse with Nokogiri" do
      #$log.info(graph.generate_graphml)
      expect {Nokogiri::XML(graph.generate_graphml) }.to_not raise_error
    end
    it "should have one node per document" do
      expect(xml.xpath("//xmlns:node").length).to eq(8)
    end
  end

end

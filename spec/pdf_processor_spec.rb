require 'spec_helper'
require_relative "../lib/pdf_processor"

describe 'PdfProcessor' do

  def get_filepath(filename)
    File.expand_path("#{File.dirname(__FILE__)}/../docs/guide_resources/#{filename}")
  end
  let(:pdfp0) do
    path0=File.expand_path("#{File.dirname(__FILE__)}/../spec/fixtures/empty_pdf.pdf")
    PdfProcessor.new(path0)
  end
  let(:pdfp1) {PdfProcessor.new(get_filepath("2010_Kiritchenko_et_al_ExaCT_automatic_extraction_of_clinical_trial_characteristics_from_journal_publications.pdf"))}
  let(:pdfp2) {PdfProcessor.new(get_filepath("2016_Howard et al._SWIFT-Review A text-mining workbench for systematic review.pdf"))}
  let(:pdfp3) {PdfProcessor.new(get_filepath("2013_Uribe_et_al_Herramienta_para_la_automatizacion_de_la_revision_sistematica.pdf"))}

  context "on empty pdf" do
    let(:abstract) {pdfp0.abstract}
    it 'should retrieve nil abstract' do
      expect(abstract).to be_nil
    end
    it 'should retrieve nil doi' do
      expect(pdfp0.get_doi).to be_nil
    end
    it 'should retrieve nil title' do
      expect(pdfp0.title).to be_nil
    end
    it 'should retrieve nil author' do
      expect(pdfp0.author).to be_nil
    end
    it 'should retrieve nil keywords' do
      expect(pdfp0.keywords).to be_nil
    end

  end
  context "on Kiritchenko(2010)" do
    let(:abstract) {pdfp1.abstract}
    it 'should retrieve the abstract' do
      expect(abstract).to_not include("Abstract")
      expect(abstract).to include("Background:")
      expect(abstract).to include("Conclusions:")
      expect(abstract).to_not include("The overall result of this bottleneck")
    end
    it 'should retrieve nil keywords' do
      expect(pdfp0.keywords).to be_nil
    end

  end
  context "on Howard(2016)" do
    let(:abstract) {pdfp2.abstract}
    it 'should retrieve the abstract' do
      #$log.info(abstract)
      expect(abstract).to_not include("Abstract")
      expect(abstract).to include("Background:")
      expect(abstract).to include("Conclusions:")
      expect(abstract).to_not include("Keywords")
    end
    it 'should retrieve correct keywords' do
      expect(pdfp2.keywords).to eq(["SWIFT-Review","Systematic review","Literature prioritization","Scoping reports","Software"])
    end

  end
  context "on Uribe et al.(2013)" do
    let(:abstract) {pdfp3.abstract}
    it 'should retrieve the abstract' do
      #abstract.chars do |c|
      #  $log.info "%s %3d %02X" % [ c, c.ord, c.ord ]
      #end
      expect(abstract).to include("Systematic Reviews provide to the researchers")
      expect(abstract).to_not include("Keywords")
    end
    it 'should retrieve correct keywords' do
      expect(pdfp3.keywords).to eq(["Systematic Review", "Protocol", "Tools"])
    end

  end

end
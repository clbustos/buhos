require 'spec_helper'
require_relative "../lib/pdf_processor"

describe 'PdfProcessor' do

  def get_filepath(filename)
    File.expand_path("#{File.dirname(__FILE__)}/../docs/guide_resources/#{filename}")
  end

  before(:all) do
    empty_pdf=File.expand_path("#{File.dirname(__FILE__)}/../spec/fixtures/empty_pdf.pdf")
    @pdfp0=PdfProcessor.new(empty_pdf)
    @pdfp1=PdfProcessor.new(get_filepath("2010_Kiritchenko_et_al_ExaCT_automatic_extraction_of_clinical_trial_characteristics_from_journal_publications.pdf"))
    @pdfp2=PdfProcessor.new(get_filepath("2016_Howard et al._SWIFT-Review A text-mining workbench for systematic review.pdf"))
    @pdfp3=PdfProcessor.new(get_filepath("2013_Uribe_et_al_Herramienta_para_la_automatizacion_de_la_revision_sistematica.pdf"))
    @abstract0=@pdfp0.abstract
    @doi0=@pdfp0.get_doi
    @title0=@pdfp0.title
    @author0=@pdfp0.author
    @keywords0=@pdfp0.keywords
    @abstract1=@pdfp1.abstract
    @abstract2=@pdfp2.abstract
    @keywords2=@pdfp2.keywords
    @abstract3=@pdfp3.abstract
    @keywords3=@pdfp3.keywords
  end

  context "on empty pdf" do
    it 'should retrieve nil abstract' do
      expect(@abstract0).to be_nil
    end
    it 'should retrieve nil doi' do
      expect(@doi0).to be_nil
    end
    it 'should retrieve nil title' do
      expect(@title0).to be_nil
    end
    it 'should retrieve nil author' do
      expect(@author0).to be_nil
    end
    it 'should retrieve nil keywords' do
      expect(@keywords0).to be_nil
    end

  end
  context "on Kiritchenko(2010)" do
    it 'should retrieve the abstract' do
      expect(@abstract1).to_not include("Abstract")
      expect(@abstract1).to include("Background:")
      expect(@abstract1).to include("Conclusions:")
      expect(@abstract1).to_not include("The overall result of this bottleneck")
    end
    it 'should retrieve nil keywords' do
      expect(@keywords0).to be_nil
    end

  end
  context "on Howard(2016)" do
    it 'should retrieve the abstract' do
      #$log.info(abstract)
      expect(@abstract2).to_not include("Abstract")
      expect(@abstract2).to include("Background:")
      expect(@abstract2).to include("Conclusions:")
      expect(@abstract2).to_not include("Keywords")
    end
    it 'should retrieve correct keywords' do
      expect(@keywords2).to eq(["SWIFT-Review","Systematic review","Literature prioritization","Scoping reports","Software"])
    end

  end
  context "on Uribe et al.(2013)" do
    it 'should retrieve the abstract' do
      #abstract.chars do |c|
      #  $log.info "%s %3d %02X" % [ c, c.ord, c.ord ]
      #end
      expect(@abstract3).to include("Systematic Reviews provide to the researchers")
      expect(@abstract3).to_not include("Keywords")
    end
    it 'should retrieve correct keywords' do
      expect(@keywords3).to eq(["Systematic Review", "Protocol", "Tools"])
    end

  end

end

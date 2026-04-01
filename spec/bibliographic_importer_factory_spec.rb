require 'spec_helper'
require_relative "../lib/bibliographical_importer/factory"


describe BibliographicalImporter::Factory do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
  end

  let(:file_body) { "some content" }
  let(:filename) { "test_file.txt" }
  let(:filetype) { "text/plain" }
  let(:result) { Result.new() }

  subject(:factory) { described_class.new(file_body, filename, filetype, result) }

  describe ".build" do
    it "instantiates and calls process" do
      expect_any_instance_of(described_class).to receive(:process)
      described_class.build(file_body, filename, filetype, result)
    end
  end

  describe "#process" do
    context "when file_body is nil" do
      let(:file_body) { nil }
      it "returns an error message" do
        expect(result).to receive(:error).with(::I18n.t('bibliographic_file_processor.no_file_available'))
        factory.process
      end
    end

    context "when file type is unknown" do
      let(:filetype) { nil }
      it "returns an error regarding no integrator" do
        expect(result).to receive(:error).with(::I18n.t('bibliographic_file_processor.no_integrator_for_filetype'))
        factory.process
      end
    end
  end

  describe "Format Detection" do
    it "detects RIS by extension" do
      f = described_class.new(file_body, "data.ris", "", result)
      expect(f.ris?).to be_truthy
    end

    it "detects JSON by mime type or extension" do
      f1 = described_class.new(file_body, "data.json", "", result)
      f2 = described_class.new(file_body, "data.txt", "application/json", result)
      expect(f1.json?).to be_truthy
      expect(f2.json?).to be_truthy
    end

    it "detects BibTeX by extension or mime type" do
      f1 = described_class.new(file_body, "refs.bib", "", result)
      f2 = described_class.new(file_body, "refs.txt", "text/x-bibtex", result)
      expect(f1.bibtex?).to be_truthy
      expect(f2.bibtex?).to be_truthy
    end

    it "detects Pubmed by extension or mime type" do
      f1 = described_class.new(file_body, "study.nbib", "", result)
      f2 = described_class.new(file_body, "study.txt", "application/nbib", result)
      expect(f1.pubmed?).to be_truthy
      expect(f2.pubmed?).to be_truthy
    end
  end

  describe "Parsing Logic" do
    context "correct BibTeX" do
      let(:file_body) { "@article{minimal2024,
  title = {A Minimal Research Paper},
  author = {Bustos, Claudio},
  journal = {Journal of Testing},
  year = {2024},
  doi = {10.1000/123456}
}" }
      let(:filename) { "manual.bib" }

      it "returns a success message" do
        expect(result).to receive(:success).with(::I18n.t('bibliographic_file_processor.bibtex_success'))
        factory.process
      end

      it "process returns a Bibtex object" do
        o=factory.process
        expect(o).to be_a(BibliographicalImporter::BibTex::Reader)
      end

    end

    context "wrong BibTeX" do
      # Missing comma
      let(:file_body){
        "@article{e54f5cb18c375b227251430cdcd4d51a0142c1c11a92680c0033dc9c3f889ef6,
  title = {Contradicciones, malestares y dilemas en la intervención social con adolescentes y },
  author = {Marco Arocas, Elisabet AND Castillo Charfolet, Aurora AND González Goya, Edurne},
  url = {https://hdl.handle.net/20.500.14454/2673},
  year = {2023},
  note = {},
  abstract={Description: La migración de adolescentes y jóvenes de forma autónoma }
  language = {spa},
}"
        #read_fixture("busqueda_base_enr_2019_2024.bib")
        #
        #
        }
      let(:filename) { "manual.bib" }

      it "returns a failure message" do
        factory.process
        expect(result.message).to include(::I18n.t('bibliographic_file_processor.bibtex_integrator_failed'))
      end

      it "process returns nil" do
        f1 = described_class.new(file_body, filename, filetype, result)
        o=f1.process
        expect(o).to be_nil
      end

    end



  end
end
require 'spec_helper'
require_relative "../lib/ris_reader"

describe 'RisReader' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
  end
  context "when ilacs is used" do
    before(:context) do
      @ris_readers=RisReader.new(read_fixture("lilacs_test.ris"))
      @ris_readers.process
    end
    it "should return 5 records" do
      expect(@ris_readers.records.length).to eq(5)
    end
    it "should return correct first author for first record" do
      expect(@ris_readers.records[0]["AU"][0]).to eq("Vásquez-Ventura, I.S.")
    end
    it "should return correct volume record" do
      expect(@ris_readers.records[0]["VL"]).to eq("18")
    end
    it "should return correct publication year record" do
      expect(@ris_readers.records[0]["PY"]).to eq("2021")
    end
    it "should return correct journal record" do
      expect(@ris_readers.records[0]["JO"]).to eq("Enferm. univ")
    end

    it "should return correct pages" do
      expect(@ris_readers.records[0]["SP"]).to eq("112")
      expect(@ris_readers.records[0]["EP"]).to eq("127")
    end
    it "should return correct DOI" do
      expect(@ris_readers.records[0]["DO"]).to eq("10.22201/eneo.23958421e.2021.2.934")
    end
    it "should return include Acculturation as KW" do
      expect(@ris_readers.records[0]["KW"].include? "Acculturation").to be_truthy
    end

    it "should return 3 abstract for first record" do
      expect(@ris_readers.records[0]["AB"].length).to eq(3)
    end
  end

  context "when proquest is used" do
    before(:context) do
      @ris_readers=RisReader.new(read_fixture("proquest_test.ris"))
      @ris_readers.process
    end
    it "should return 11 records" do
      expect(@ris_readers.records.length).to eq(11)
    end
    it "should return correct first author for first record" do
      expect(@ris_readers.records[0]["AU"][0]).to eq("Picón-Jaimes, Yelson Alejandro")
    end
    it "should return correct volume record" do
      expect(@ris_readers.records[0]["VL"]).to eq("13")
    end
    it "should return correct journal record" do
      expect(@ris_readers.records[0]["JF"]).to eq("Journal of Primary Care & Community Health")
    end

    it "should return correct pages" do
      expect(@ris_readers.records[1]["SP"]).to eq("1")
      expect(@ris_readers.records[1]["EP"]).to eq("10")
    end
    it "should return correct DOI" do
      expect(@ris_readers.records[0]["DO"]).to eq("https://doi.org/10.1177/21501319221121462")
    end
    it "should return include Acculturation as KW" do
      expect(@ris_readers.records[0]["KW"].include? "Chile").to be_truthy
    end

    it "should return 3 abstract for first record" do
      expect(@ris_readers.records[0]["AB"].include? "Introduction").to be_truthy
    end
  end

  context "when wos is used" do
    before(:context) do
      @ris_readers=RisReader.new(read_fixture("wos.ris"))
      @ris_readers.process
    end
    it "should return 11 records" do
      expect(@ris_readers.records.length).to eq(4)
    end
    it "should return correct first author for first record" do
      expect(@ris_readers.records[0]["AU"][0]).to eq("Sánchez-García, ID")
    end
    it "should return correct volume record" do
      expect(@ris_readers.records[0]["VL"]).to eq("128")
    end
    it "should return correct journal record" do
      expect(@ris_readers.records[0]["JI"]).to eq("Comput. Secur.")
    end

    it "should return correct pages" do
      expect(@ris_readers.records[0]["SP"]).to eq("2263")
      expect(@ris_readers.records[0]["EP"]).to eq("2274")
    end
    it "should return correct DOI" do
      expect(@ris_readers.records[0]["DO"]).to eq("10.1109/TLA.2022.9885164")
    end
    it "should return include Risk management as KW" do
      expect(@ris_readers.records[0]["KW"].include? "Risk management").to be_truthy
    end

    it "should return 1 abstract for first record" do
      expect(@ris_readers.records[0]["AB"].include? "Cybersecurity continues").to be_truthy
    end
  end





end
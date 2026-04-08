# frozen_string_literal: true

require "docit"

RSpec.describe Docit do
  it "has a version number" do
    expect(Docit::VERSION).not_to be nil
  end

  describe ".configuration" do
    it "returns a Configuration instance" do
      expect(Docit.configuration).to be_a(Docit::Configuration)
    end

    it "returns the same instance on repeated calls" do
      expect(Docit.configuration).to equal(Docit.configuration)
    end
  end

  describe ".configure" do
    after { Docit.reset_configuration! }

    it "yields the configuration object" do
      Docit.configure do |config|
        config.title = "Test API"
        config.version = "2.0.0"
      end

      expect(Docit.configuration.title).to eq("Test API")
      expect(Docit.configuration.version).to eq("2.0.0")
    end
  end
end

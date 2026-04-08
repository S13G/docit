# frozen_string_literal: true

require "docket"

RSpec.describe Docket do
  it "has a version number" do
    expect(Docket::VERSION).not_to be nil
  end

  describe ".configuration" do
    it "returns a Configuration instance" do
      expect(Docket.configuration).to be_a(Docket::Configuration)
    end

    it "returns the same instance on repeated calls" do
      expect(Docket.configuration).to equal(Docket.configuration)
    end
  end

  describe ".configure" do
    after { Docket.reset_configuration! }

    it "yields the configuration object" do
      Docket.configure do |config|
        config.title = "Test API"
        config.version = "2.0.0"
      end

      expect(Docket.configuration.title).to eq("Test API")
      expect(Docket.configuration.version).to eq("2.0.0")
    end
  end
end

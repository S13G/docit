# frozen_string_literal: true

require "docit"
require "tmpdir"

RSpec.describe Docit::Ai::Configuration do
  describe "#valid?" do
    it "returns true for valid openai config" do
      config = described_class.new(provider: "openai", model: "gpt-4o", api_key: "sk-test123")
      expect(config.valid?).to be true
    end

    it "returns true for valid anthropic config" do
      config = described_class.new(provider: "anthropic", model: "claude-sonnet-4-20250514", api_key: "sk-ant-test")
      expect(config.valid?).to be true
    end

    it "returns true for valid groq config" do
      config = described_class.new(provider: "groq", model: "llama-3.3-70b-versatile", api_key: "gsk-test")
      expect(config.valid?).to be true
    end

    it "returns false for unsupported provider" do
      config = described_class.new(provider: "gemini", model: "gemini-pro", api_key: "key")
      expect(config.valid?).to be false
    end

    it "returns false for blank model" do
      config = described_class.new(provider: "openai", model: "", api_key: "key")
      expect(config.valid?).to be false
    end

    it "returns false for blank api_key" do
      config = described_class.new(provider: "openai", model: "gpt-4o", api_key: "")
      expect(config.valid?).to be false
    end
  end

  describe ".save and .load" do
    let(:tmpdir) { Dir.mktmpdir }

    before do
      root = Pathname.new(tmpdir)
      rails = Module.new
      rails.define_singleton_method(:root) { root }
      stub_const("Rails", rails)
    end

    after { FileUtils.remove_entry(tmpdir) }

    it "saves config to YAML and loads it back" do
      described_class.save(provider: "openai", model: "gpt-4o", api_key: "sk-test")

      loaded = described_class.load
      expect(loaded.provider).to eq("openai")
      expect(loaded.model).to eq("gpt-4o")
      expect(loaded.api_key).to eq("sk-test")
    end

    it "writes the config file with restricted permissions" do
      described_class.save(provider: "openai", model: "gpt-4o", api_key: "sk-test")

      mode = File.stat(described_class.config_path).mode & 0o777
      expect(mode).to eq(0o600)
    end

    it "raises on save with invalid config" do
      expect do
        described_class.save(provider: "bad", model: "x", api_key: "y")
      end.to raise_error(Docit::Error, "Invalid configuration")
    end

    it "raises on load when not configured" do
      expect do
        described_class.load
      end.to raise_error(Docit::Error, /AI not configured/)
    end

    it "reports configured? correctly" do
      expect(described_class.configured?).to be false
      described_class.save(provider: "anthropic", model: "claude-sonnet-4-20250514", api_key: "sk-ant")
      expect(described_class.configured?).to be true
    end
  end

  describe "constants" do
    it "supports openai, anthropic, and groq providers" do
      expect(described_class::PROVIDERS).to eq(%w[openai anthropic groq])
    end

    it "has default models for each provider" do
      expect(described_class::DEFAULT_MODELS.keys).to match_array(%w[openai anthropic groq])
    end
  end
end

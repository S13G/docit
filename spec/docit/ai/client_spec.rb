# frozen_string_literal: true

require "docit"

RSpec.describe Docit::Ai::Client do
  describe ".for" do
    let(:openai_config) do
      Docit::Ai::Configuration.new(provider: "openai", model: "gpt-4o", api_key: "sk-test")
    end

    let(:anthropic_config) do
      Docit::Ai::Configuration.new(provider: "anthropic", model: "claude-sonnet-4-20250514", api_key: "sk-ant")
    end

    let(:groq_config) do
      Docit::Ai::Configuration.new(provider: "groq", model: "llama-3.3-70b-versatile", api_key: "gsk-test")
    end

    it "returns OpenaiClient for openai provider" do
      client = described_class.for(openai_config)
      expect(client).to be_a(Docit::Ai::OpenaiClient)
    end

    it "returns AnthropicClient for anthropic provider" do
      client = described_class.for(anthropic_config)
      expect(client).to be_a(Docit::Ai::AnthropicClient)
    end

    it "returns GroqClient for groq provider" do
      client = described_class.for(groq_config)
      expect(client).to be_a(Docit::Ai::GroqClient)
    end

    it "raises for unsupported provider" do
      bad_config = Docit::Ai::Configuration.new(provider: "gemini", model: "x", api_key: "y")
      expect { described_class.for(bad_config) }.to raise_error(Docit::Ai::Error, /Unsupported provider/)
    end
  end
end

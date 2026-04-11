# frozen_string_literal: true

require "docit"

RSpec.describe "AI provider clients" do
  [
    [Docit::Ai::OpenaiClient, { api_key: "sk-test", model: "gpt-4o-mini" }, "OpenAI"],
    [Docit::Ai::AnthropicClient, { api_key: "sk-ant-test", model: "claude-haiku" }, "Anthropic"],
    [Docit::Ai::GroqClient, { api_key: "gsk-test", model: "llama-3.3-70b-versatile" }, "Groq"]
  ].each do |client_class, args, provider_name|
    it "raises a Docit error when #{provider_name} returns invalid JSON" do
      client = client_class.new(**args)
      response = Net::HTTPOK.new("1.1", "200", "OK")
      allow(response).to receive(:body).and_return("not-json")

      expect { client.send(:handle_response, response) }.to raise_error(
        Docit::Ai::Error,
        /#{provider_name} returned invalid JSON \(HTTP 200\)/
      )
    end
  end
end

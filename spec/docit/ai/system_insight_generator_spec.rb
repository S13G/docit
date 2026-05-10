# frozen_string_literal: true

require "docit"

RSpec.describe Docit::Ai::SystemInsightGenerator do
  it "generates an AI explanation from graph data" do
    config = Docit::Ai::Configuration.new(provider: "openai", model: "gpt-test", api_key: "sk-test")
    client = instance_double(Docit::Ai::OpenaiClient)
    graph = {
      nodes: [{ id: "route:get:/users", type: "route", label: "GET /users" }],
      edges: [],
      stats: { nodes: 1, edges: 0 }
    }

    allow(Docit::Ai::Configuration).to receive(:load).and_return(config)
    allow(Docit::Ai::Client).to receive(:for).with(config).and_return(client)
    allow(client).to receive(:generate).with(include("GET /users")).and_return("System overview")

    expect(described_class.new(graph: graph).generate).to eq("System overview")
  end
end

# frozen_string_literal: true

require "docit"

RSpec.describe Docit::SystemGraph::Graph do
  it "serializes nodes, edges, and stats" do
    graph = described_class.new
    graph.add_node(Docit::SystemGraph::Node.new(id: "controller:users", type: "controller", label: "UsersController"))
    graph.add_node(Docit::SystemGraph::Node.new(id: "action:users#index", type: "action", label: "UsersController#index"))
    graph.add_edge(Docit::SystemGraph::Edge.new(
                     id: "contains:users#index",
                     source: "controller:users",
                     target: "action:users#index",
                     type: "contains",
                     confidence: "high",
                     evidence: "test"
                   ))

    payload = graph.to_h

    expect(payload[:version]).to eq("1.0")
    expect(payload[:framework]).to eq("rails")
    expect(payload[:nodes].length).to eq(2)
    expect(payload[:edges].length).to eq(1)
    expect(payload[:stats][:node_types]).to eq({ "controller" => 1, "action" => 1 })
  end

  it "deduplicates nodes and edges by id" do
    graph = described_class.new
    node = Docit::SystemGraph::Node.new(id: "controller:users", type: "controller", label: "UsersController")
    edge = Docit::SystemGraph::Edge.new(
      id: "self",
      source: "controller:users",
      target: "controller:users",
      type: "contains",
      confidence: "high",
      evidence: "test"
    )

    2.times { graph.add_node(node) }
    2.times { graph.add_edge(edge) }

    payload = graph.to_h
    expect(payload[:nodes].length).to eq(1)
    expect(payload[:edges]).to be_empty
  end
end

# frozen_string_literal: true

require "spec_helper"

ENV["RAILS_ENV"] = "test"
require File.expand_path("../../dummy/config/environment", __dir__)

RSpec.describe Docit::SystemGraph::RailsAnalyzer do
  before do
    Api::V1::UsersController
  end

  it "builds route, controller, action, and doc coverage nodes" do
    graph = described_class.new.analyze.to_h
    nodes = graph[:nodes]
    edges = graph[:edges]

    expect(nodes).to include(hash_including(id: "route:get:/api/v1/users", type: "route", status: "documented"))
    expect(nodes).to include(hash_including(id: "controller:api:v1:users_controller", type: "controller"))
    expect(nodes).to include(hash_including(id: "controller:api:v1:users_controller#index", type: "action",
                                            status: "documented"))
    expect(nodes).to include(hash_including(id: "doc:api/v1/users_controller:index", type: "doc"))
    expect(edges).to include(hash_including(type: "routes_to", confidence: "high", evidence: "Rails route table"))
    expect(edges).to include(hash_including(type: "documents", confidence: "high", evidence: "Docit registry"))
  end

  it "skips Docit engine routes" do
    graph = described_class.new.analyze.to_h
    route_labels = graph[:nodes].select { |node| node[:type] == "route" }.map { |node| node[:label] }

    expect(route_labels).not_to include("GET /api-docs/spec")
  end

  it "honors excluded paths" do
    Docit.configuration.system_graph_excluded_paths = ["app/controllers/api/v1/users_controller.rb"]

    graph = described_class.new.analyze.to_h
    node_ids = graph[:nodes].map { |node| node[:id] }

    expect(node_ids).not_to include("controller:api:v1:users_controller")
  ensure
    Docit.configuration.system_graph_excluded_paths = []
  end

  it "extracts model nodes and association edges from ActiveRecord reflections" do
    stub_const("Author", Class.new(ActiveRecord::Base) do
      self.table_name = "authors"
      has_many :books
    end)
    stub_const("Book", Class.new(ActiveRecord::Base) do
      self.table_name = "books"
      belongs_to :author
    end)

    graph = described_class.new.analyze.to_h
    node_ids = graph[:nodes].map { |node| node[:id] }

    expect(node_ids).to include("model:author", "model:book")
    expect(graph[:edges]).to include(
      hash_including(source: "model:author", target: "model:book", type: "association", confidence: "high")
    )
  end

  it "does not crash when optional source folders (services/jobs/mailers) are absent" do
    # The dummy app has no app/services, app/jobs, or app/mailers directories.
    expect { described_class.new.analyze.to_h }.not_to raise_error

    graph = described_class.new.analyze.to_h
    expect(graph[:nodes]).to be_an(Array).and(be_any)
  end

  it "marks an action with no registered doc as undocumented" do
    Docit::Registry.clear!

    graph = described_class.new.analyze.to_h
    action = graph[:nodes].find { |node| node[:id] == "controller:api:v1:users_controller#index" }

    expect(action[:type]).to eq("action")
    expect(action[:status]).to eq("undocumented")
  end

  it "links a documented action to the schema it references via uses_schema" do
    Docit::Registry.clear!
    Docit.reset_schemas!
    Docit.define_schema(:User) { property :id, type: :integer }
    Api::V1::UsersController.doc_for(:index) do
      response 200, "OK" do
        schema ref: :User
      end
    end

    graph = described_class.new.analyze.to_h
    schema_node = graph[:nodes].find { |node| node[:id] == "schema:user" }
    uses_edge = graph[:edges].find { |edge| edge[:type] == "uses_schema" }

    expect(schema_node).not_to be_nil
    expect(uses_edge).to include(
      source: "doc:api/v1/users_controller:index",
      target: "schema:user",
      confidence: "high"
    )
    # the edge must point at a real node, not a dangling id
    expect(uses_edge[:target]).to eq(schema_node[:id])
  ensure
    Docit::Registry.clear!
    Docit.reset_schemas!
  end
end

# frozen_string_literal: true

require "spec_helper"

ENV["RAILS_ENV"] = "test"
require File.expand_path("../../dummy/config/environment", __dir__)

RSpec.describe Docit::SystemGraph::RailsAnalyzer do
  before do
    Api::V1::AuthController
    Api::V1::UsersController
  end

  it "builds route, controller, action, and doc coverage nodes" do
    graph = described_class.new.analyze.to_h
    nodes = graph[:nodes]
    edges = graph[:edges]

    expect(nodes).to include(hash_including(id: "route:get:/api/v1/users", type: "route", status: "documented"))
    expect(nodes).to include(hash_including(id: "controller:api:v1:users_controller", type: "controller"))
    expect(nodes).to include(hash_including(id: "controller:api:v1:users_controller#index", type: "action", status: "documented"))
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
end

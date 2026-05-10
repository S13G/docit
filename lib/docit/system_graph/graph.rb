# frozen_string_literal: true

require "time"

module Docit
  module SystemGraph
    class Graph
      VERSION = "1.0"

      attr_reader :nodes, :edges, :framework

      def initialize(framework: "rails")
        @framework = framework
        @nodes = {}
        @edges = {}
      end

      def add_node(node)
        nodes[node.id] ||= node
      end

      def add_edge(edge)
        return if edge.source == edge.target
        return unless nodes.key?(edge.source) && nodes.key?(edge.target)

        edges[edge.id] ||= edge
      end

      def to_h
        node_values = nodes.values
        edge_values = edges.values

        {
          version: VERSION,
          generated_at: Time.now.utc.iso8601,
          framework: framework,
          nodes: node_values.map(&:to_h),
          edges: edge_values.map(&:to_h),
          stats: stats(node_values, edge_values)
        }
      end

      private

      def stats(node_values, edge_values)
        {
          nodes: node_values.length,
          edges: edge_values.length,
          node_types: node_values.group_by(&:type).transform_values(&:length),
          edge_types: edge_values.group_by(&:type).transform_values(&:length)
        }
      end
    end
  end
end

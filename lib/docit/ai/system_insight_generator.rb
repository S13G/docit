# frozen_string_literal: true

require "json"

module Docit
  module Ai
    class SystemInsightGenerator
      def initialize(graph:, selected_node_ids: [])
        @graph = graph
        @selected_node_ids = selected_node_ids
      end

      def generate
        config = Configuration.load
        Client.for(config).generate(prompt)
      end

      private

      attr_reader :graph, :selected_node_ids

      def prompt
        <<~PROMPT
          You are a senior engineer explaining a Rails system architecture to a junior developer who is seeing this codebase for the first time. Your goal is to make them feel confident and informed.

          IMPORTANT RULES:
          - Use simple, everyday language. Avoid jargon unless you define it first.
          - Be specific — reference actual controller names, model names, and endpoints from the graph.
          - If a relationship is only likely (not confirmed by an edge), say "likely" and explain your reasoning.
          - Use ONLY facts from the provided graph JSON. Do not invent components.

          FORMAT YOUR RESPONSE EXACTLY LIKE THIS:

          ## Overview
          A 2-3 sentence plain-English summary of what this part of the system does. Think of it as explaining to a friend what this code is for.

          ## How It Works (Step by Step)
          Walk through the request/data flow as numbered steps:
          1. A user/client sends a request to [endpoint]
          2. Rails routes it to [controller#action]
          3. The action does [what it does]
          ...continue until the response is sent back.

          ## Component Breakdown
          For each selected component:
          - **ComponentName** (type): What it does in plain English. Why it exists.

          ## Relationships & Connections
          Explain which components talk to each other and why:
          - ComponentA → ComponentB: Why this connection exists
          - ComponentC → ComponentD: What data flows between them

          ## Watch Out For
          List anything a junior engineer should be careful about:
          - Missing documentation
          - Complex relationships
          - Potential gotchas

          ## Request Flow
          Show the flow using plain text arrows. For example:
            Client → GET /api/v1/users
              → UsersController#index
              → queries User model
              → returns 200 JSON response

          Keep it simple and linear. Do NOT use Mermaid or any diagram syntax. Just plain indented text with → arrows.

          ---

          Selected node ids:
          #{selected_node_ids.join("\n")}

          Graph JSON:
          #{JSON.pretty_generate(compact_graph)}
        PROMPT
      end

      def compact_graph
        nodes = selected_nodes
        node_ids = nodes.map { |node| node[:id] }

        # Include edges where at least one end is in the selection
        related_edges = graph[:edges].select do |edge|
          node_ids.include?(edge[:source]) || node_ids.include?(edge[:target])
        end

        # Also include neighbor nodes (one hop away) for context
        neighbor_ids = Set.new(node_ids)
        related_edges.each do |edge|
          neighbor_ids.add(edge[:source])
          neighbor_ids.add(edge[:target])
        end

        neighbor_nodes = graph[:nodes].select { |node| neighbor_ids.include?(node[:id]) }

        {
          selected_nodes: nodes.map { |node| compact_hash(node, %i[id type label status file metadata]) },
          context_nodes: (neighbor_nodes - nodes).map { |node| compact_hash(node, %i[id type label status]) },
          edges: related_edges.map { |edge| compact_hash(edge, %i[source target type confidence evidence]) },
          stats: graph[:stats]
        }
      end

      def selected_nodes
        return graph[:nodes] if selected_node_ids.empty?

        graph[:nodes].select { |node| selected_node_ids.include?(node[:id]) }
      end

      def compact_hash(hash, keys)
        keys.each_with_object({}) do |key, result|
          result[key] = hash[key] if hash.key?(key)
        end
      end
    end
  end
end

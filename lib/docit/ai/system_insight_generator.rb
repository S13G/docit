# frozen_string_literal: true

require "json"

module Docit
  module Ai
    class SystemInsightGenerator
      # mode: :nodes  -> explain an arbitrary selection (diagram "AI Explain")
      #       :section -> explain one resource and how its endpoints work together
      def initialize(graph:, selected_node_ids: [], mode: :nodes)
        @graph = graph
        @selected_node_ids = selected_node_ids
        @mode = mode
      end

      def generate
        config = Configuration.load
        Client.for(config).generate(prompt)
      end

      private

      attr_reader :graph, :selected_node_ids, :mode

      def prompt
        mode == :section ? section_prompt : nodes_prompt
      end

      def nodes_prompt
        <<~PROMPT
          You are a senior engineer explaining a Rails system architecture to a developer. Keep your explanation extremely concise, professional, and clear. Avoid fluff, unnecessary details, or general tutorial information. Focus only on the provided components.

          FORMAT YOUR RESPONSE EXACTLY LIKE THIS:

          ## Overview
          A 1-2 sentence plain-English summary of what this component/action does.

          ## Data Flow
          Show a simple, linear flow diagram using text and arrows (→). Keep it to 1 line if possible.
          Example:
            Client → GET /api/v1/users → UsersController#index → queries User model

          ## Connections & Interactions
          List only the direct, relevant relationships from the graph (max 3 bullets):
          - **Component** (type): Action details/purpose.

          Do not invent or assume anything outside of the provided graph. Keep the total response under 150 words.

          ---

          Selected node ids:
          #{selected_node_ids.join("\n")}

          Graph JSON:
          #{JSON.pretty_generate(compact_graph)}
        PROMPT
      end

      def section_prompt
        <<~PROMPT
          You are a senior engineer writing the introduction to a section of API documentation. The section covers ONE resource and all of its endpoints. Explain, for a developer new to this codebase, what the resource is for and how its endpoints work together as a workflow.

          Use the documented summaries where available. Where an endpoint has no documentation, infer cautiously from its HTTP method and path, and do not fabricate behavior.

          FORMAT YOUR RESPONSE EXACTLY LIKE THIS:

          ## What this section does
          1-2 sentences on the resource and its overall purpose.

          ## How the endpoints work together
          A short narrative (2-4 sentences) describing the typical flow across these endpoints — e.g. how a client lists, creates, then updates this resource. Reference endpoints by their HTTP method and path.

          ## Notes
          Up to 2 bullets on related models/services or anything a consumer must know. Omit this section if there is nothing concrete to say.

          Do not invent endpoints, fields, or behavior not present in the graph. Keep the total response under 180 words.

          ---

          Endpoint node ids in this section:
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

# frozen_string_literal: true

module Docit
  module SystemGraph
    class RailsAnalyzer
      VALID_METHODS = %w[get post put patch delete].freeze
      SKIP_PREFIXES = %w[docit/ rails/ active_storage/ action_mailbox/].freeze

      def initialize(graph: Graph.new, scanner: SourceScanner.new(root: Rails.root))
        @graph = graph
        @scanner = scanner
      end

      def analyze
        add_routes_and_actions
        add_schemas
        add_models
        add_source_nodes
        # Runs last: Graph#add_edge drops edges to not-yet-created nodes, so
        # schema-usage edges must be added after both doc and schema nodes exist.
        add_schema_usage_edges
        graph
      end

      private

      attr_reader :graph, :scanner

      def add_routes_and_actions
        route_infos.each do |info|
          controller_id = node_id("controller", info[:controller])
          action_id = "#{controller_id}##{info[:action]}"
          route_id = "route:#{info[:method]}:#{info[:path]}"
          operation = Registry.find(controller: info[:controller], action: info[:action])

          graph.add_node(Node.new(
                           id: controller_id,
                           type: "controller",
                           label: info[:controller],
                           file: controller_file(info[:controller]),
                           metadata: { controller_path: info[:controller_path] }
                         ))
          graph.add_node(Node.new(
                           id: action_id,
                           type: "action",
                           label: "#{info[:controller]}##{info[:action]}",
                           file: controller_file(info[:controller]),
                           status: operation ? "documented" : "undocumented",
                           metadata: { action: info[:action], http_method: info[:method], path: info[:path] }
                         ))
          graph.add_node(Node.new(
                           id: route_id,
                           type: "route",
                           label: "#{info[:method].upcase} #{info[:path]}",
                           metadata: { method: info[:method], path: info[:path] },
                           status: operation ? "documented" : "undocumented"
                         ))

          graph.add_edge(edge(route_id, action_id, "routes_to", "high", "Rails route table"))
          graph.add_edge(edge(controller_id, action_id, "contains", "high", "Rails controller action"))
          add_doc_node(info, operation, action_id) if operation
        end
      end

      def add_doc_node(info, operation, action_id)
        doc_id = "doc:#{info[:controller].underscore}:#{info[:action]}"

        request_body_info = nil
        if operation._request_body
          request_body_info = {
            required: operation._request_body.required,
            content_type: operation._request_body.content_type,
            schema_ref: operation._request_body.schema_ref,
            properties: operation._request_body.properties
          }
        end

        responses_info = operation._responses.map do |res|
          {
            status: res.status,
            description: res.description,
            schema_ref: res.schema_ref,
            properties: res.properties,
            examples: res.examples
          }
        end

        parameters_info = operation._parameters.params.map do |param|
          {
            name: param[:name],
            location: param[:in],
            type: param[:schema][:type],
            required: param[:required],
            description: param[:description]
          }
        end

        graph.add_node(Node.new(
                         id: doc_id,
                         type: "doc",
                         label: operation._summary || "#{info[:controller]}##{info[:action]}",
                         metadata: {
                           controller: info[:controller],
                           action: info[:action],
                           description: operation._description,
                           tags: operation._tags,
                           request_body: request_body_info,
                           responses: responses_info,
                           parameters: parameters_info
                         },
                         status: "documented"
                       ))
        graph.add_edge(edge(doc_id, action_id, "documents", "high", "Docit registry"))
      end

      # Link each doc node to every shared schema it references via $ref (in its
      # request body or any response). Runs as a final pass because add_edge only
      # keeps edges whose endpoints already exist as nodes. Confidence is high —
      # the references come straight from the Docit registry.
      def add_schema_usage_edges
        graph.nodes.values.select { |node| node.type == "doc" }.each do |doc|
          operation = Registry.find(controller: doc.metadata[:controller], action: doc.metadata[:action])
          next unless operation

          schema_refs_for(operation).each do |ref|
            graph.add_edge(edge(doc.id, node_id("schema", ref), "uses_schema", "high", "Docit registry $ref"))
          end
        end
      end

      def schema_refs_for(operation)
        refs = [operation._request_body&.schema_ref]
        operation._responses.each { |res| refs << res.schema_ref }
        refs.compact.uniq
      end

      def add_schemas
        Docit.schemas.each_key do |name|
          graph.add_node(Node.new(
                           id: node_id("schema", name),
                           type: "schema",
                           label: name.to_s,
                           metadata: { properties: Docit.schemas[name].properties.map { |prop| prop[:name].to_s } }
                         ))
        end
      end

      def add_models
        return unless defined?(ActiveRecord::Base)

        ActiveRecord::Base.descendants.each do |model|
          next if model.name.nil?

          model_id = node_id("model", model.name)
          graph.add_node(Node.new(
                           id: model_id,
                           type: "model",
                           label: model.name,
                           file: model_file(model.name),
                           metadata: { table_name: table_name(model) }
                         ))
          add_model_associations(model, model_id)
        end
      end

      def add_model_associations(model, model_id)
        return unless model.respond_to?(:reflect_on_all_associations)

        model.reflect_on_all_associations.each do |association|
          target = association.class_name
          target_id = node_id("model", target)
          next unless graph.nodes.key?(target_id)

          graph.add_edge(edge(model_id, target_id, "association", "high",
                              "ActiveRecord reflection: #{association.name}"))
        end
      end

      def add_source_nodes
        source_nodes = scanner.source_nodes
        source_nodes.each { |node| graph.add_node(node) }

        labels = graph.nodes.values.select { |node| %w[model service job mailer].include?(node.type) }.map(&:label)
        sources = graph.nodes.values.select { |node| %w[controller action service job mailer].include?(node.type) }
        sources.each do |source|
          scanner.references_for(source.file, labels).each do |label|
            target = graph.nodes.values.find { |node| node.label == label }
            next unless target

            graph.add_edge(edge(source.id, target.id, edge_type_for(target), "medium",
                                "Constant reference in #{source.file}"))
          end
        end
      end

      def route_infos
        return [] if defined?(Rails).nil? || Rails.application.routes.nil?

        Rails.application.routes.routes.filter_map do |route|
          controller_path = route.defaults[:controller]
          action = route.defaults[:action]
          next if controller_path.nil? || action.nil?
          next if skip_route?(controller_path)

          method = extract_verb(route)
          next if VALID_METHODS.exclude?(method)

          controller = "#{controller_path}_controller".camelize
          next if excluded_path?(controller_file(controller))

          {
            controller: controller,
            controller_path: controller_path,
            action: action.to_s,
            method: method,
            path: normalize_path(route.path.spec.to_s)
          }
        end.uniq
      end

      def edge(source, target, type, confidence, evidence)
        Edge.new(
          id: "#{type}:#{source}->#{target}",
          source: source,
          target: target,
          type: type,
          confidence: confidence,
          evidence: evidence
        )
      end

      def node_id(type, label)
        "#{type}:#{label.to_s.underscore.tr("/", ":")}"
      end

      def controller_file(controller)
        "app/controllers/#{controller.underscore}.rb"
      end

      def model_file(model)
        "app/models/#{model.underscore}.rb"
      end

      def edge_type_for(target)
        target.type == "model" ? "uses_model" : "calls"
      end

      def table_name(model)
        model.table_name if model.respond_to?(:table_name)
      rescue ActiveRecord::StatementInvalid
        nil
      end

      def skip_route?(controller_path)
        SKIP_PREFIXES.any? { |prefix| controller_path.start_with?(prefix) }
      end

      def excluded_path?(path)
        Docit.configuration.system_graph_excluded_paths.any? do |excluded|
          path.start_with?(excluded.to_s)
        end
      end

      def extract_verb(route)
        verb = route.verb
        verb = verb.source if verb.is_a?(Regexp)
        verb.to_s.downcase.gsub(/[^a-z]/, "")
      end

      def normalize_path(path)
        path
          .gsub("(.:format)", "")
          .gsub(/\(\.?:(\w+)\)/, '{\1}')
          .gsub(/:(\w+)/, '{\1}')
      end
    end
  end
end

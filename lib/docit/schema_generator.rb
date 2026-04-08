# frozen_string_literal: true

module Docit
  # Converts the Registry of operations and Configuration into an OpenAPI 3.0.3 spec hash.
  class SchemaGenerator
    def self.generate
      new.generate
    end

    def generate
      config = Docit.configuration

      spec = {
        openapi: "3.0.3",
        info: {
          title: config.title,
          version: config.version,
          description: config.description
        },
        paths: build_paths,
        components: {
          securitySchemes: config.security_schemes
        }
      }

      tag_defs = config.tags
      spec[:tags] = tag_defs if tag_defs.any?

      server_defs = config.servers
      spec[:servers] = server_defs if server_defs.any?

      schemas = build_component_schemas
      spec[:components][:schemas] = schemas if schemas.any?

      spec
    end

    private

    def build_paths
      paths = {}

      Docit::Registry.operations.each do |operation|
        routes = RouteInspector.routes_for(operation.controller, operation.action)
        next if routes.empty?

        routes.each do |route|
          path = route[:path]
          method = route[:method]

          paths[path] ||= {}
          paths[path][method] = build_operation(operation)
        end
      end

      paths
    end

    def build_operation(operation)
      result = {
        summary: operation._summary || operation.action.humanize,
        description: operation._description || "",
        tags: operation._tags,
        responses: build_responses(operation._responses)
      }

      params = operation._parameters.params
      result[:parameters] = params if params.any?

      result[:requestBody] = build_request_body(operation._request_body) if operation._request_body
      result[:deprecated] = true if operation._deprecated
      result[:security] = operation._security.map { |s| { s.to_s => [] } } if operation._security.any?

      result
    end

    def build_responses(response_builders)
      return { "200" => { description: "Success" } } if response_builders.empty?

      response_builders.each_with_object({}) do |builder, hash|
        entry = { description: builder.description }

        if builder.schema_ref
          schema = { "$ref" => "#/components/schemas/#{builder.schema_ref}" }
          content = { "application/json" => { schema: schema } }
          content["application/json"][:examples] = build_examples(builder.examples) if builder.examples.any?
          entry[:content] = content
        elsif builder.properties.any?
          schema = {
            type: "object",
            properties: build_properties(builder.properties)
          }
          content = { "application/json" => { schema: schema } }
          content["application/json"][:examples] = build_examples(builder.examples) if builder.examples.any?
          entry[:content] = content
        end

        hash[builder.status.to_s] = entry
      end
    end

    def build_request_body(request_body_builder)
      if request_body_builder.schema_ref
        schema = { "$ref" => "#/components/schemas/#{request_body_builder.schema_ref}" }
      else
        schema = {
          type: "object",
          properties: build_properties(request_body_builder.properties)
        }

        required_properties = request_body_builder.required_properties
        schema[:required] = required_properties if required_properties.any?
      end

      {
        required: request_body_builder.required,
        content: {
          request_body_builder.content_type => { schema: schema }
        }
      }
    end

    def build_properties(props)
      props.each_with_object({}) do |prop, hash|
        schema = build_property_schema(prop)
        hash[prop[:name].to_s] = schema
      end
    end

    def build_property_schema(prop)
      type = prop[:type].to_s

      if type == "file"
        schema = { type: "string", format: "binary" }
        schema[:description] = prop[:description] if prop[:description]
        schema
      elsif type == "array"
        schema = { type: "array" }
        if prop[:children]
          schema[:items] = {
            type: "object",
            properties: build_properties(prop[:children])
          }
        else
          items_type = prop[:items]&.to_s || "string"
          schema[:items] = { type: items_type }
        end
        schema[:description] = prop[:description] if prop[:description]
        schema[:example] = prop[:example] if prop[:example]
        schema
      elsif type == "object" && prop[:children]
        schema = {
          type: "object",
          properties: build_properties(prop[:children])
        }
        schema[:description] = prop[:description] if prop[:description]
        schema[:example] = prop[:example] if prop[:example]
        schema
      else
        schema = { type: type }
        schema[:format] = prop[:format].to_s if prop[:format]
        schema[:enum] = prop[:enum] if prop[:enum]
        schema[:example] = prop[:example] if prop[:example]
        schema[:description] = prop[:description] if prop[:description]
        schema
      end
    end

    def build_component_schemas
      Docit.schemas.each_with_object({}) do |(name, definition), hash|
        schema = {
          type: "object",
          properties: build_properties(definition.properties)
        }
        hash[name.to_s] = schema
      end
    end

    def build_examples(examples)
      examples.each_with_object({}) do |ex, hash|
        entry = { value: ex[:value] }
        entry[:description] = ex[:description] if ex[:description]
        hash[ex[:name].to_s] = entry
      end
    end
  end
end

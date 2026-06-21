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
        info: build_info(config),
        paths: build_paths,
        components: {
          securitySchemes: config.security_schemes
        }
      }

      # Top-level security applies to every operation unless an operation
      # overrides it (a documented scheme, or `security :none` to opt out).
      spec[:security] = config.default_security.map { |s| { s.to_s => [] } } if config.default_security?

      tag_defs = config.tags
      spec[:tags] = tag_defs if tag_defs.any?

      server_defs = config.servers
      spec[:servers] = server_defs if server_defs.any?

      schemas = build_component_schemas
      spec[:components][:schemas] = schemas if schemas.any?

      spec
    end

    private

    def build_info(config)
      info = {
        title: config.title,
        version: config.version,
        description: config.description
      }
      info[:license] = config.license_info if config.license_info
      info[:contact] = config.contact_info if config.contact_info
      info[:termsOfService] = config.terms_of_service_url if config.terms_of_service_url
      info
    end

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
        operationId: operation._operation_id || generate_operation_id(operation),
        summary: operation._summary || operation.action.humanize,
        description: operation._description || "",
        tags: operation._tags,
        responses: build_responses(operation._responses)
      }

      params = operation._parameters.params
      result[:parameters] = params if params.any?

      result[:requestBody] = build_request_body(operation._request_body) if operation._request_body
      result[:deprecated] = true if operation._deprecated
      security = build_operation_security(operation)
      result[:security] = security unless security.nil?

      result
    end

    def build_operation_security(operation)
      return nil if operation._security.empty?
      return [] if operation._security.map(&:to_sym) == [:none]

      operation._security.reject { |s| s.to_sym == :none }.map { |s| { s.to_s => [] } }
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

        entry[:headers] = build_response_headers(builder.headers) if builder.headers.any?

        hash[builder.status.to_s] = entry
      end
    end

    def build_response_headers(headers)
      headers.each_with_object({}) do |header, hash|
        schema = { schema: { type: header[:type] } }
        schema[:description] = header[:description] if header[:description]
        schema[:schema][:example] = header[:example] if header.key?(:example)
        hash[header[:name]] = schema
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
      schema = base_property_schema(type, prop)

      # These OpenAPI fields apply to any property shape, so set them once here
      # rather than in each branch above. nil-checks let `false`/`0` through as
      # explicit values (e.g. default: false), but skip unset options.
      schema[:description] = prop[:description] if prop[:description]
      schema[:example] = prop[:example] if prop[:example]
      schema[:default] = prop[:default] unless prop[:default].nil?
      schema[:nullable] = prop[:nullable] unless prop[:nullable].nil?
      schema[:readOnly] = prop[:read_only] unless prop[:read_only].nil?
      schema[:writeOnly] = prop[:write_only] unless prop[:write_only].nil?
      schema
    end

    def base_property_schema(type, prop)
      case type
      when "file"
        { type: "string", format: "binary" }
      when "array"
        { type: "array", items: array_items_schema(prop) }
      else
        # An object with declared children becomes a nested schema; everything
        # else (including a childless "object") is a scalar with type/format/enum.
        if type == "object" && prop[:children]
          { type: "object", properties: build_properties(prop[:children]) }
        else
          scalar_property_schema(type, prop)
        end
      end
    end

    def array_items_schema(prop)
      return { type: "object", properties: build_properties(prop[:children]) } if prop[:children]

      { type: prop[:items]&.to_s || "string" }
    end

    def scalar_property_schema(type, prop)
      schema = { type: type }
      schema[:format] = prop[:format].to_s if prop[:format]
      schema[:enum] = prop[:enum] if prop[:enum]
      schema
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

    def generate_operation_id(operation)
      # "Api::V1::UsersController" → "users" ; "index" → "listUsers"
      resource = operation.controller
                          .gsub(/.*::/, "") # strip namespace
                          .gsub(/Controller$/, "") # strip suffix
      action = operation.action

      "#{action}_#{resource}".gsub("::", "_").downcase
    end
  end
end

# frozen_string_literal: true

module Docit
  module Builders
    # Builds the schema for a request body, including properties,
    # required fields, and schema references.
    class RequestBodyBuilder
      attr_reader :properties, :required, :content_type, :schema_ref

      def initialize(required: false, content_type: "application/json")
        @required = required
        @content_type = content_type
        @properties = []
        @schema_ref = nil
      end

      def schema(ref:)
        @schema_ref = ref.to_sym
      end

      def property(name, type:, required: false, format: nil, example: nil, enum: nil, description: nil, items: nil,
                   **opts, &block)
        prop = { name: name, type: type, required: required }
        prop[:format] = format if format
        prop[:example] = example if example
        prop[:enum] = enum if enum
        prop[:description] = description if description
        prop[:items] = items if items
        prop.merge!(opts)

        if block_given?
          nested = self.class.new(required: @required, content_type: @content_type)
          nested.instance_eval(&block)
          prop[:children] = nested.properties
        end

        @properties << prop
      end

      def required_properties
        @properties.select { |prop| prop[:required] }.map { |prop| prop[:name].to_s }
      end
    end
  end
end

# frozen_string_literal: true

module Docket
  module Builders
    # Builds the schema for a single HTTP response, including properties,
    # examples, and schema references.
    class ResponseBuilder
      attr_reader :status, :description, :properties, :examples, :schema_ref

      def initialize(status:, description:)
        @status = status
        @description = description
        @properties = []
        @examples = []
        @schema_ref = nil
      end

      def schema(ref:)
        @schema_ref = ref.to_sym
      end

      def property(name, type:, format: nil, example: nil, enum: nil, description: nil, items: nil, **opts, &block)
        prop = { name: name, type: type }
        prop[:format] = format if format
        prop[:example] = example if example
        prop[:enum] = enum if enum
        prop[:description] = description if description
        prop[:items] = items if items
        prop.merge!(opts)

        if block_given?
          nested = self.class.new(status: @status, description: @description)
          nested.instance_eval(&block)
          prop[:children] = nested.properties
        end

        @properties << prop
      end

      def example(name, value, description: nil)
        ex = { name: name, value: value }
        ex[:description] = description if description
        @examples << ex
      end
    end
  end
end

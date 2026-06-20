# frozen_string_literal: true

module Docit
  module Builders
    # Builds the schema for a single HTTP response, including properties,
    # examples, headers, and schema references.
    class ResponseBuilder
      attr_reader :status, :description, :properties, :examples, :headers, :schema_ref

      def initialize(status:, description:)
        @status = status
        @description = description
        @properties = []
        @examples = []
        @headers = []
        @schema_ref = nil
      end

      def schema(ref:)
        @schema_ref = ref.to_sym
      end

      # Declares a response header, e.g. a rate-limit or pagination header:
      #   header "X-RateLimit-Remaining", type: :integer, description: "..."
      def header(name, type: :string, description: nil, example: nil)
        entry = { name: name.to_s, type: type.to_s }
        entry[:description] = description if description
        entry[:example] = example unless example.nil?
        @headers << entry
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

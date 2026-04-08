# frozen_string_literal: true

module Docket
  module Builders
    class ResponseBuilder
      attr_reader :status, :description, :properties, :examples

      def initialize(status:, description:)
        @status = status
        @description = description
        @properties = []
        @examples = []
      end

      def property(name, type:, format: nil, example: nil, enum: nil, description: nil, **opts)
        prop = { name: name, type: type }
        prop[:format] = format if format
        prop[:example] = example if example
        prop[:enum] = enum if enum
        prop[:description] = description if description
        prop.merge!(opts)
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

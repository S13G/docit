# frozen_string_literal: true

module Docket
  module Builders
    class RequestBodyBuilder
      attr_reader :properties, :required, :content_type

      def initialize(required: false, content_type: "application/json")
        @required = required
        @content_type = content_type
        @properties = []
      end

      def property(name, type:, required: false, format: nil, example: nil, enum: nil, description: nil, **opts)
        prop = { name: name, type: type, required: required }
        prop[:format] = format if format
        prop[:example] = example if example
        prop[:enum] = enum if enum
        prop[:description] = description if description
        prop.merge!(opts)
        @properties << prop
      end

      def required_properties
        @properties.select { |prop| prop[:required] }.map { |prop| prop[:name].to_s }
      end
    end
  end
end

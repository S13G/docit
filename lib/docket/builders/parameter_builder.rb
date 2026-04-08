# frozen_string_literal: true

module Docket
  module Builders
    # Collects query, path, and header parameters for an operation.
    class ParameterBuilder
      attr_reader :params

      def initialize
        @params = []
      end

      def add(name, location:, type: :string, required: false, description: nil, example: nil, enum: nil, **opts)
        param = {
          name: name.to_s,
          in: location.to_s,
          required: required,
          schema: { type: type.to_s }
        }
        param[:description] = description if description
        param[:schema][:enum] = enum if enum
        param[:schema][:example] = example if example
        param[:schema].merge!(opts)
        @params << param
      end
    end
  end
end

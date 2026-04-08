# frozen_string_literal: true

module Docit
  # A reusable schema definition that can be referenced via +$ref+.
  # Defined with {Docit.define_schema} and rendered under
  # +components/schemas+ in the OpenAPI spec.
  class SchemaDefinition
    attr_reader :name, :properties

    def initialize(name)
      @name = name
      @properties = []
    end

    def property(prop_name, type:, format: nil, example: nil, enum: nil, description: nil, items: nil, **opts, &block)
      prop = { name: prop_name, type: type }
      prop[:format] = format if format
      prop[:example] = example if example
      prop[:enum] = enum if enum
      prop[:description] = description if description
      prop[:items] = items if items
      prop.merge!(opts)

      if block_given?
        nested = self.class.new(:"#{@name}_#{prop_name}")
        nested.instance_eval(&block)
        prop[:children] = nested.properties
      end

      @properties << prop
    end
  end
end

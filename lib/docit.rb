# frozen_string_literal: true

require_relative "docit/version"
require_relative "docit/configuration"
require_relative "docit/registry"
require_relative "docit/builders/request_body_builder"
require_relative "docit/builders/response_builder"
require_relative "docit/builders/parameter_builder"
require_relative "docit/operation"
require_relative "docit/schema_definition"
require_relative "docit/doc_file"
require_relative "docit/route_inspector"
require_relative "docit/schema_generator"
require_relative "docit/dsl"

# Docit is a decorator-style API documentation gem for Ruby on Rails.
# It generates OpenAPI 3.0.3 specs from clean DSL macros on your controllers.
module Docit
  class Error < StandardError; end

  class << self
    def configure
      yield configuration
    end

    def configuration
      @configuration ||= Configuration.new
    end

    def reset_configuration!
      @configuration = Configuration.new
    end

    def schemas
      @schemas ||= {}
    end

    def define_schema(name, &block)
      definition = SchemaDefinition.new(name)
      definition.instance_eval(&block) if block_given?
      schemas[name.to_sym] = definition
    end

    def reset_schemas!
      @schemas = {}
    end
  end
end

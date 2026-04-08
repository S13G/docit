# frozen_string_literal: true

require_relative "docket/version"
require_relative "docket/configuration"
require_relative "docket/registry"
require_relative "docket/builders/request_body_builder"
require_relative "docket/builders/response_builder"
require_relative "docket/builders/parameter_builder"
require_relative "docket/operation"
require_relative "docket/schema_definition"
require_relative "docket/doc_file"
require_relative "docket/route_inspector"
require_relative "docket/schema_generator"
require_relative "docket/dsl"

# Docket is a decorator-style API documentation gem for Ruby on Rails.
# It generates OpenAPI 3.0.3 specs from clean DSL macros on your controllers.
module Docket
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

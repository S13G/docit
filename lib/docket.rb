# frozen_string_literal: true

require_relative "docket/version"
require_relative "docket/configuration"
require_relative "docket/registry"
require_relative "docket/builders/request_body_builder"
require_relative "docket/builders/response_builder"
require_relative "docket/builders/parameter_builder"
require_relative "docket/operation"
require_relative "docket/route_inspector"
require_relative "docket/schema_generator"
require_relative "docket/dsl"

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
  end
end

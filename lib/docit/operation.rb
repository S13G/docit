# frozen_string_literal: true

module Docit
  # Represents the documentation for a single controller action.
  # Created by +doc_for+ and stored in the {Registry}.
  class Operation
    attr_reader :controller, :action, :_summary, :_description,
                :_tags, :_responses, :_request_body, :_parameters,
                :_security, :_deprecated, :_operation_id

    def initialize(controller:, action:)
      @controller = controller
      @action = action.to_s
      @_tags = []
      @_responses = []
      @_parameters = Builders::ParameterBuilder.new
      @_request_body = nil
      @_security = []
      @_deprecated = false
      @_operation_id = nil
    end

    def summary(text)
      @_summary = text
    end

    def description(text)
      @_description = text
    end

    def tags(*tags_list)
      @_tags = tags_list.flatten
    end

    def deprecated(value: true)
      @_deprecated = value
    end

    def operation_id(text)
      @_operation_id = text
    end

    def security(scheme)
      @_security << scheme
    end

    def parameter(name, location:, type: :string, required: false, description: nil, **opts)
      @_parameters.add(name, location: location, type: type, required: required, description: description, **opts)
    end

    def request_body(required: false, content_type: "application/json", &block)
      builder = Builders::RequestBodyBuilder.new(required: required, content_type: content_type)
      builder.instance_eval(&block) if block_given?
      @_request_body = builder
    end

    def response(status, description = "", &block)
      builder = Builders::ResponseBuilder.new(status: status, description: description)
      builder.instance_eval(&block) if block_given?
      @_responses << builder
    end
  end
end

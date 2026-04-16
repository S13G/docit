# frozen_string_literal: true

module Docit
  module Ai
    class InvalidDocBlockError < Error; end

    class DocBlockValidator
      def initialize(controller:, action:, doc_block:)
        @controller = controller
        @action = action.to_sym
        @doc_block = doc_block
      end

      def validate!
        doc_module = Module.new
        doc_module.extend(Docit::DocFile)
        doc_module.module_eval(@doc_block, "(generated Docit block)", 1)

        validate_actions!(doc_module.actions)

        operation = Docit::Operation.new(controller: @controller, action: @action)
        operation.instance_eval(&doc_module[@action])

        true
      rescue SyntaxError, StandardError => e
        raise InvalidDocBlockError, error_message_for(e)
      end

      private

      def validate_actions!(actions)
        return if actions == [@action]

        raise InvalidDocBlockError, "Generated output did not define a doc block" if actions.empty?

        action_list = actions.map { |action| ":#{action}" }.join(", ")
        raise InvalidDocBlockError,
              "Generated output must define only doc :#{@action}, got #{action_list}"
      end

      def error_message_for(error)
        return error.message if error.is_a?(InvalidDocBlockError)

        "#{error.class}: #{error.message}"
      end
    end
  end
end

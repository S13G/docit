# frozen_string_literal: true

module Docit
  # Central store for all documented operations.
  class Registry
    class << self
      def operations
        @operations ||= []
      end

      def register(operation)
        existing_index = operations.index do |registered_operation|
          registered_operation.controller == operation.controller &&
            registered_operation.action == operation.action
        end

        if existing_index
          operations[existing_index] = operation
        else
          operations << operation
        end
      end

      def find(controller:, action:)
        operations.find do |op|
          op.controller == controller && op.action == action
        end
      end

      def clear!
        @operations = []
      end
    end
  end
end

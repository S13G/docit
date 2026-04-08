# frozen_string_literal: true

module Docket
  class Registry
    class << self
      def operations
        @operations ||= []
      end

      def register(operation)
        operations << operation
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

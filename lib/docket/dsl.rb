# frozen_string_literal: true

module Docket
  module DSL
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def swagger_doc(action, &block)
        operation = Operation.new(
          controller: name,
          action: action
        )
        operation.instance_eval(&block) if block_given?
        Registry.register(operation)
      end
    end
  end
end

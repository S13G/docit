# frozen_string_literal: true

module Docket
  # Included in all Rails controllers via the Engine.
  # Provides +swagger_doc+ and +use_docs+ class methods.
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

      def use_docs(doc_module)
        doc_module.actions.each do |action|
          swagger_doc(action, &doc_module[action])
        end
      end
    end
  end
end

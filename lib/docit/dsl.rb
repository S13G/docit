# frozen_string_literal: true

module Docit
  # Included in all Rails controllers via the Engine.
  # Provides +doc_for+ and +use_docs+ class methods.
  module DSL
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def doc_for(action, &block)
        operation = Operation.new(
          controller: name,
          action: action
        )
        operation.instance_eval(&block) if block_given?
        Registry.register(operation)
      end

      # Backward-compatible alias
      alias swagger_doc doc_for

      def use_docs(doc_module)
        doc_module.actions.each do |action|
          doc_for(action, &doc_module[action])
        end
      end
    end
  end
end

# frozen_string_literal: true

module Docit
  module SystemGraph
    class Edge
      attr_reader :id, :source, :target, :type, :confidence, :evidence

      def initialize(id:, source:, target:, type:, confidence:, evidence:)
        @id = id.to_s
        @source = source.to_s
        @target = target.to_s
        @type = type.to_s
        @confidence = confidence.to_s
        @evidence = evidence.to_s
      end

      def to_h
        {
          id: id,
          source: source,
          target: target,
          type: type,
          confidence: confidence,
          evidence: evidence
        }
      end
    end
  end
end

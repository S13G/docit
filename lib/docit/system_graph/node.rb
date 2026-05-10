# frozen_string_literal: true

module Docit
  module SystemGraph
    class Node
      attr_reader :id, :type, :label, :metadata, :file, :line, :status

      def initialize(id:, type:, label:, metadata: {}, file: nil, line: nil, status: nil)
        @id = id.to_s
        @type = type.to_s
        @label = label.to_s
        @metadata = metadata
        @file = file
        @line = line
        @status = status
      end

      def to_h
        {
          id: id,
          type: type,
          label: label,
          metadata: metadata
        }.tap do |hash|
          hash[:file] = file if file
          hash[:line] = line if line
          hash[:status] = status if status
        end
      end
    end
  end
end

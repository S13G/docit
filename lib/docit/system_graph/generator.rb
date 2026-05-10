# frozen_string_literal: true

module Docit
  module SystemGraph
    class Generator
      def self.generate
        new.generate
      end

      def generate
        RailsAnalyzer.new.analyze.to_h
      end
    end
  end
end

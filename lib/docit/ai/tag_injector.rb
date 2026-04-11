# frozen_string_literal: true

module Docit
  module Ai
    class TagInjector
      def initialize(tags:)
        @tags = tags.uniq
      end

      def inject
        return [] if initializer_path && File.exist?(initializer_path) == false

        content = File.read(initializer_path)
        existing_tags = content.scan(/config\.tag\s+["']([^"']+)["']/).flatten

        new_tags = @tags - existing_tags
        return [] if new_tags.empty?

        lines = new_tags.map do |tag|
          desc = "#{tag} management endpoints"
          "  config.tag \"#{tag}\", description: \"#{desc}\""
        end

        insertion_point = find_insertion_point(content)
        return [] if insertion_point.nil?

        content = content.insert(insertion_point, "\n#{lines.join("\n")}")
        File.write(initializer_path, content)

        new_tags
      end

      private

      def initializer_path
        return nil if defined?(Rails) == false

        Rails.root.join("config", "initializers", "docit.rb").to_s
      end

      def find_insertion_point(content)
        last_tag = content.rindex(/config\.tag\s+/)
        if last_tag
          content.index("\n", last_tag)
        else
          last_config = content.rindex(/config\.\w+/)
          content.index("\n", last_config) if last_config
        end
      end
    end
  end
end

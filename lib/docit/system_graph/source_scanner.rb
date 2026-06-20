# frozen_string_literal: true

module Docit
  module SystemGraph
    class SourceScanner
      SOURCE_TYPES = {
        "app/services" => "service",
        "app/jobs" => "job",
        "app/mailers" => "mailer"
      }.freeze

      def initialize(root:, excluded_paths: Docit.configuration.system_graph_excluded_paths)
        @root = root
        @excluded_paths = excluded_paths.map(&:to_s)
      end

      def source_nodes
        SOURCE_TYPES.each_with_object([]) do |(dir, type), nodes|
          scan_dir(dir).each do |path|
            relative = relative_path(path)
            label = constant_name(relative, dir)
            nodes << Node.new(
              id: node_id(type, label),
              type: type,
              label: label,
              file: relative,
              metadata: { path: relative }
            )
          end
        end
      end

      def references_for(path, candidates)
        return [] unless path && File.exist?(full_path(path))

        content = File.read(full_path(path))
        candidates.select do |candidate|
          content.match?(/\b#{Regexp.escape(candidate)}\b/)
        end
      end

      private

      attr_reader :root, :excluded_paths

      def scan_dir(dir)
        full_dir = root.join(dir)
        return [] unless Dir.exist?(full_dir)

        Dir.glob(full_dir.join("**", "*.rb")).sort.reject do |path|
          excluded?(relative_path(path))
        end
      end

      def relative_path(path)
        path.to_s.sub("#{root}/", "")
      end

      def constant_name(relative, dir)
        relative.delete_prefix("#{dir}/").delete_suffix(".rb").camelize
      end

      def node_id(type, label)
        "#{type}:#{label.underscore.tr("/", ":")}"
      end

      def full_path(path)
        root.join(path)
      end

      def excluded?(path)
        excluded_paths.any? { |excluded| path.start_with?(excluded) }
      end
    end
  end
end

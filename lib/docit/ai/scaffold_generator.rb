# frozen_string_literal: true

require "fileutils"
require "active_support/core_ext/string/inflections"

module Docit
  module Ai
    class ScaffoldGenerator
      def initialize(output: $stdout)
        @output = output
        @files_written = []
      end

      def run
        check_base_setup!
        gaps = detect_gaps

        if gaps.empty?
          @output.puts "No undocumented endpoints found."
          return @files_written
        end

        @output.puts "Found #{gaps.length} endpoint#{"s" if gaps.length > 1} to scaffold:"
        gaps.each { |g| @output.puts "  #{g[:method].upcase} #{g[:path]} (#{g[:controller]}##{g[:action]})" }
        @output.puts ""

        grouped = gaps.group_by { |g| g[:controller] }

        grouped.each do |controller, controller_gaps|
          writer = DocWriter.new(controller_name: controller)

          if writer.file_exists?
            existing_actions = existing_doc_actions(writer.doc_file_path)
            controller_gaps = controller_gaps.reject { |g| existing_actions.include?(g[:action]) }
            next if controller_gaps.empty?
          end

          blocks = controller_gaps.map { |gap| build_placeholder(gap, controller) }
          writer.write(blocks)
          @files_written << writer.doc_file_path

          relative = writer.doc_file_path.sub("#{Rails.root}/", "")
          @output.puts "  Created: #{relative}"

          if writer.inject_use_docs
            controller_relative = File.join("app", "controllers", "#{controller.underscore}.rb")
            @output.puts "  Added use_docs to #{controller_relative}"
          end
        end

        inject_tags(grouped)

        @output.puts ""
        @output.puts "Scaffolded #{gaps.length} endpoint#{"s" if gaps.length > 1} in #{@files_written.length} file#{"s" if @files_written.length > 1}."
        @output.puts "Fill in the TODO placeholders in your doc files."
        @files_written
      end

      private

      def detect_gaps
        RouteInspector.eager_load_controllers!

        detector = GapDetector.new
        detector.detect
      end

      def check_base_setup!
        unless defined?(Rails) && Rails.respond_to?(:root) && Rails.root
          raise Docit::Error, "Docit requires a Rails application. Run this command from your app root."
        end

        initializer = Rails.root.join("config", "initializers", "docit.rb")
        return unless File.exist?(initializer) == false

        raise Docit::Error, "Docit is not installed. Run: rails generate docit:install"
      end

      def build_placeholder(gap, controller)
        tag = derive_tag(controller)
        method = gap[:method].upcase
        path = gap[:path]

        lines = []
        lines << "doc :#{gap[:action]} do"
        lines << "  summary \"TODO: #{method} #{path}\""
        lines << "  tags \"#{tag}\""

        if gap[:path].include?("{")
          path_params = gap[:path].scan(/\{(\w+)\}/).flatten
          path_params.each do |param|
            lines << "  parameter :#{param}, location: :path, type: :string, required: true"
          end
        end

        if %w[POST PUT PATCH].include?(method)
          lines << ""
          lines << "  request_body required: true do"
          lines << "    # TODO: Add request properties"
          lines << "    # property :name, type: :string, required: true"
          lines << "  end"
        end

        lines << ""
        lines << "  response #{default_status(method)}, \"TODO: Add description\" do"
        lines << "    # TODO: Add response properties"
        lines << "    # property :id, type: :integer"
        lines << "  end"
        lines << "end"

        lines.join("\n")
      end

      def derive_tag(controller)
        controller.delete_suffix("Controller").split("::").last
      end

      def default_status(method)
        case method
        when "POST" then 201
        when "DELETE" then 204
        else 200
        end
      end

      def existing_doc_actions(path)
        content = File.read(path)
        content.scan(/doc\s+:(\w+)/).flatten
      end

      def inject_tags(grouped)
        tags = grouped.keys.map { |c| derive_tag(c) }.uniq
        return if tags.empty?

        injected = TagInjector.new(tags: tags).inject
        injected.each { |tag| @output.puts "  Added tag \"#{tag}\" to config/initializers/docit.rb" }
      end
    end
  end
end

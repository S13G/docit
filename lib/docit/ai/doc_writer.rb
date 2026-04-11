# frozen_string_literal: true

require "fileutils"
require "active_support/core_ext/string/inflections"

module Docit
  module Ai
    class DocWriter
      def initialize(controller_name:)
        @controller_name = controller_name
        @module_parts = build_module_parts
      end

      def doc_file_path
        parts = @controller_name.underscore.delete_suffix("_controller").split("/")
        filename = "#{parts.last}_docs.rb"
        dir_parts = parts[0..-2]

        File.join(Rails.root, "app", "docs", *dir_parts, filename)
      end

      def doc_module_name
        @controller_name.delete_suffix("Controller").gsub("::", "::") + "Docs"
      end

      def file_exists?
        File.exist?(doc_file_path)
      end

      def controller_has_use_docs?
        path = controller_file_path
        return false if path && File.exist?(path) == false

        File.read(path).include?("use_docs")
      end

      def inject_use_docs
        path = controller_file_path
        return false if path && File.exist?(path) == false
        return false if controller_has_use_docs?

        content = File.read(path)
        class_pattern = /^(\s*class\s+\S+.*$)/
        match = content.match(class_pattern)
        return false if match.nil?

        indent = match[1][/^\s*/] + "  "
        use_docs_line = "#{indent}use_docs #{doc_module_name}\n"
        content = content.sub(class_pattern, "\\1\n#{use_docs_line}")

        File.write(path, content)
        true
      end

      def write(doc_blocks)
        if file_exists?
          append_to_existing(doc_blocks)
        else
          create_new_file(doc_blocks)
        end
      end

      private

      def create_new_file(doc_blocks)
        FileUtils.mkdir_p(File.dirname(doc_file_path))

        content = build_new_file_content(doc_blocks)
        File.write(doc_file_path, content)
      end

      def append_to_existing(doc_blocks)
        content = File.read(doc_file_path)
        insertion = doc_blocks.map { |block| indent_block(block, @module_parts.length + 1) }.join("\n\n")
        closing_ends = "end\n" * @module_parts.length

        content = content.rstrip
        content = content.delete_suffix(closing_ends.rstrip)
        content = "#{content.rstrip}\n\n#{insertion}\n#{closing_ends}"

        File.write(doc_file_path, content)
      end

      def build_new_file_content(doc_blocks)
        lines = ["# frozen_string_literal: true", ""]

        @module_parts.each_with_index do |part, i|
          lines << "#{"  " * i}module #{part}"
        end

        depth = @module_parts.length
        lines << "#{"  " * depth}extend Docit::DocFile"

        doc_blocks.each do |block|
          lines << ""
          lines << indent_block(block, depth)
        end

        @module_parts.length.times do |i|
          lines << "#{"  " * (@module_parts.length - 1 - i)}end"
        end

        lines.join("\n") + "\n"
      end

      def indent_block(block, depth)
        prefix = "  " * depth
        block.strip.lines.map { |line| line.rstrip.empty? ? "" : "#{prefix}#{line.rstrip}" }.join("\n")
      end

      def build_module_parts
        doc_module_name.split("::")
      end

      def controller_file_path
        Rails.root.join("app", "controllers", "#{@controller_name.underscore}.rb").to_s
      end
    end
  end
end

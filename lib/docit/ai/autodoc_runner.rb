# frozen_string_literal: true

module Docit
  module Ai
    class AutodocRunner
      attr_reader :results

      def initialize(controller_filter: nil, dry_run: false, input: $stdin, output: $stdout)
        @controller_filter = controller_filter
        @dry_run = dry_run
        @input = input
        @output = output
        @results = { gaps: [], generated: 0, files: [], tags: [] }
      end

      def run
        check_base_setup!
        config = load_config
        @output.puts "Using #{config.provider}"
        @output.puts ""

        gaps = detect_gaps
        @results[:gaps] = gaps

        if gaps.empty?
          @output.puts "All endpoints are documented!"
          return @results
        end

        print_gaps(gaps)

        if @dry_run
          @output.puts "[dry-run] No files written."
          return @results
        end

        confirm_source_upload!(config)
        generated = generate_docs(gaps, config)
        write_docs(generated)
        inject_tags(generated)

        @output.puts "Review generated files and edit as needed."
        @results
      end

      private

      def load_config
        Docit::Ai::Configuration.load
      end

      def check_base_setup!
        if !(defined?(Rails) && Rails.respond_to?(:root) && Rails.root)
          raise Docit::Error, "Docit requires a Rails application. Run this command from your app root."
        end

        initializer = Rails.root.join("config", "initializers", "docit.rb")
        if File.exist?(initializer) == false
          raise Docit::Error, "Docit is not installed. Run: rails generate docit:install"
        end

        routes_file = Rails.root.join("config", "routes.rb")
        if File.exist?(routes_file) && !File.read(routes_file).include?("Docit::Engine")
          @output.puts "Warning: Docit engine is not mounted in config/routes.rb"
          @output.puts "  Run: rails generate docit:install (or add: mount Docit::Engine => \"/api-docs\")"
          @output.puts ""
        end
      end

      def detect_gaps
        detector = GapDetector.new(controller_filter: @controller_filter)
        detector.detect
      end

      def print_gaps(gaps)
        @output.puts "Found #{gaps.length} undocumented endpoint#{"s" if gaps.length > 1}:"
        gaps.each { |g| @output.puts "  #{g[:method].upcase} #{g[:path]} (#{g[:controller]}##{g[:action]})" }
        @output.puts ""
      end

      def confirm_source_upload!(config)
        @output.puts "Docit will send controller source code to #{config.provider.capitalize} to generate documentation."
        @output.puts "Review the endpoints first if they contain secrets or proprietary logic."

        return if !(@input.respond_to?(:tty?) && @input.tty?)

        loop do
          @output.print "Continue? (y/n): "
          choice = @input.gets.to_s.strip.downcase

          case choice
          when "y", "yes"
            @output.puts ""
            return
          when "n", "no"
            raise Docit::Error, "Autodoc cancelled."
          else
            @output.puts "Please enter y or n."
          end
        end
      end

      def generate_docs(gaps, config)
        client = Client.for(config)
        generated = Hash.new { |h, k| h[k] = [] }
        max_retries = 3

        @output.puts "Generating documentation............."

        gaps.each_with_index do |gap, index|
          @output.print "[#{index + 1}/#{gaps.length}] Generating #{gap[:controller]}##{gap[:action]}..."

          builder = PromptBuilder.new(gap: gap)
          if builder.source_available? == false
            @output.puts " skipped (controller source file not found)"
            next
          end

          prompt = builder.build
          retries = 0

          begin
            doc_block = client.generate(prompt).strip
            doc_block = strip_markdown_fences(doc_block)

            generated[gap[:controller]] << doc_block
            @results[:generated] += 1
            @output.puts " done"
          rescue Docit::Ai::RateLimitError => e
            retries += 1
            if retries <= max_retries
              wait = e.retry_after || (2**retries * 10)
              wait = [wait, 300].min # cap at 5 minutes
              @output.puts " rate limited, waiting #{wait.round}s (attempt #{retries}/#{max_retries})..."
              sleep(wait)
              retry
            else
              @output.puts " failed (rate limit exceeded after #{max_retries} retries)"
            end
          rescue Docit::Ai::Error => e
            @output.puts " failed (#{e.message})"
          end
        end

        generated
      end

      def write_docs(generated)
        generated.each do |controller, blocks|
          next if blocks.empty?

          writer = DocWriter.new(controller_name: controller)
          writer.write(blocks)
          @results[:files] << writer.doc_file_path

          relative = writer.doc_file_path.sub("#{Rails.root}/", "")
          @output.puts "  Wrote: #{relative}"

          if writer.inject_use_docs
            controller_relative = File.join("app", "controllers", "#{controller.underscore}.rb")
            @output.puts "  Added use_docs to #{controller_relative}"
          end
        end

        @output.puts ""
        @output.puts "Generated docs for #{@results[:generated]} endpoint#{"s" if @results[:generated] > 1} in #{@results[:files].length} file#{"s" if @results[:files].length > 1}."
      end

      def inject_tags(generated)
        all_tags = generated.values.flatten.join("\n").scan(/tags\s+["']([^"']+)["']/).flatten
        return unless all_tags.any?

        injected = TagInjector.new(tags: all_tags).inject
        injected.each { |tag| @output.puts "  Added tag \"#{tag}\" to config/initializers/docit.rb" }
        @results[:tags] = injected
      end

      def strip_markdown_fences(text)
        text = text.sub(/\A```\w*\n/, "")
        text.sub(/\n```\z/, "")
      end
    end
  end
end

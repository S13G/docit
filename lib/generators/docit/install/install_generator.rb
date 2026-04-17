# frozen_string_literal: true

require "io/console"

module Docit
  module Generators
    class InstallGenerator < Rails::Generators::Base
      desc "Creates a Docit initializer, mounts the engine, and sets up documentation"
      source_root File.expand_path("templates", __dir__)

      PROVIDER_OPTIONS = {
        "1" => "openai",
        "2" => "anthropic",
        "3" => "groq"
      }.freeze

      def copy_initializer
        template "initializer.rb", "config/initializers/docit.rb"
      end

      def mount_engine
        route 'mount Docit::Engine => "/api-docs"'
      end

      def ask_doc_mode
        say ""
        say "How would you like to set up your API documentation?", :green
        say "  1. AI automatic docs (generate docs using AI)"
        say "  2. Manual docs (create scaffolded placeholders to fill in)"
        say "  3. Skip for now, I'll do it myself (just set up the engine and initializer)"
        say ""

        @doc_mode = ask_choice("Enter choice (1-3):", %w[1 2 3])
      end

      def setup_docs
        case @doc_mode
        when "1"
          run_ai_setup
        when "2"
          run_manual_scaffold
        else
          print_skip_instructions
        end
      end

      private

      def run_ai_setup
        say ""
        say "--- AI Documentation Setup ---", :yellow
        say ""

        provider = prompt_provider
        api_key = prompt_api_key(provider)
        save_ai_configuration(provider, api_key)
        update_gitignore

        say ""
        say "Scanning project for undocumented endpoints...", :yellow
        say ""

        runner = Docit::Ai::AutodocRunner.new(output: shell_output)
        runner.run

        say ""
        say "Docit installed and AI docs generated!", :green
        say ""
        say "Next steps:"
        say "  1. Review generated doc files in app/docs/"
        say "  2. Edit config/initializers/docit.rb to customize settings"
        say "  3. Start your server and visit /api-docs"
        say ""
        say "To regenerate docs later:"
        say "  rails docit:autodoc"
        say ""
      end

      def run_manual_scaffold
        say ""
        say "--- Manual Documentation Setup ---", :yellow
        say ""
        say "Scanning project for endpoints...", :yellow
        say ""

        scaffold = Docit::Ai::ScaffoldGenerator.new(output: shell_output)
        scaffold.run

        say ""
        say "Docit installed with doc scaffolds!", :green
        say ""
        say "Next steps:"
        say "  1. Fill in the TODO placeholders in your doc files under app/docs/"
        say "  2. Edit config/initializers/docit.rb to customize settings"
        say "  3. Start your server and visit /api-docs"
        say ""
      end

      def print_skip_instructions
        say ""
        say "Docit installed successfully!", :green
        say ""
        say "Next steps:"
        say "  1. Edit config/initializers/docit.rb to customize your API docs"
        say "  2. Add doc_for blocks or create doc files under app/docs/"
        say "  3. Visit /api-docs to see your Swagger UI"
        say ""
        say "You can set up docs later with:"
        say "  rails generate docit:ai_setup   # configure AI provider"
        say "  rails docit:autodoc             # generate docs with AI"
        say ""
      end

      def prompt_provider
        say "Select your AI provider:"
        say "  1. OpenAI"
        say "  2. Anthropic"
        say "  3. Groq (free tier available)"
        say ""

        choice = ask_choice("Enter choice (1-3):", PROVIDER_OPTIONS.keys)
        provider = PROVIDER_OPTIONS[choice]

        say "Selected: #{provider.capitalize}", :green
        provider
      end

      def prompt_api_key(provider)
        loop do
          api_key = ask_secret("Enter your #{provider.capitalize} API key:")
          return api_key if api_key.empty? == false

          say "API key cannot be blank.", :red
        end
      end

      def save_ai_configuration(provider, api_key)
        model = Docit::Ai::Configuration::DEFAULT_MODELS[provider]
        Docit::Ai::Configuration.save(
          provider: provider,
          model: model,
          api_key: api_key
        )
        say "Saved AI configuration to .docit_ai.yml", :green
      end

      def update_gitignore
        gitignore = Rails.root.join(".gitignore")
        unless File.exist?(gitignore)
          say "Warning: .gitignore not found. Add .docit_ai.yml manually to avoid committing your API key.", :yellow
          return
        end

        content = File.read(gitignore)
        return if content.include?(".docit_ai.yml")

        File.open(gitignore, "a") do |f|
          f.puts "" unless content.end_with?("\n")
          f.puts "# Docit AI configuration (contains API key)"
          f.puts ".docit_ai.yml"
        end
        say "Added .docit_ai.yml to .gitignore", :green
      end

      def ask_choice(prompt, choices)
        loop do
          choice = ask(prompt).to_s.strip
          return choice if choices.include?(choice)

          say "Invalid choice. Please enter #{choices.join(", ")}.", :red
        end
      end

      def ask_secret(prompt)
        if $stdin.respond_to?(:noecho) && $stdin.tty?
          shell.say(prompt, nil, false)
          value = $stdin.noecho(&:gets).to_s.strip
          shell.say("")
          value
        else
          ask(prompt).to_s.strip
        end
      end

      def shell_output
        @shell_output ||= ShellOutput.new(shell)
      end

      class ShellOutput
        def initialize(shell)
          @shell = shell
        end

        def puts(msg = "")
          @shell.say(msg)
        end

        def print(msg)
          @shell.say(msg, nil, false)
        end
      end
    end
  end
end

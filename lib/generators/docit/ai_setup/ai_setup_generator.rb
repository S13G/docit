# frozen_string_literal: true

require "io/console"

module Docit
  module Generators
    class AiSetupGenerator < Rails::Generators::Base
      desc "Configures AI provider for Docit autodoc generation"

      PROVIDER_OPTIONS = {
        "1" => "openai",
        "2" => "anthropic",
        "3" => "groq"
      }.freeze

      def prompt_provider
        say ""
        say "Select your AI provider:"
        say "  1. OpenAI"
        say "  2. Anthropic"
        say "  3. Groq (free tier available)"
        say ""

        choice = ask_choice("Enter choice (1-3):", PROVIDER_OPTIONS.keys)
        @provider = PROVIDER_OPTIONS[choice]

        say "Selected: #{@provider.capitalize}", :green
      end

      def prompt_api_key
        loop do
          @api_key = ask_secret("Enter your #{@provider.capitalize} API key:")
          return if @api_key.empty? == false

          say "API key cannot be blank", :red
        end
      end

      def save_configuration
        model = Docit::Ai::Configuration::DEFAULT_MODELS[@provider]
        Docit::Ai::Configuration.save(
          provider: @provider,
          model: model,
          api_key: @api_key
        )
        say "Saved AI configuration to .docit_ai.yml", :green
      end

      def update_gitignore
        gitignore = Rails.root.join(".gitignore")
        if File.exist?(gitignore) == false
          say "Warning: .gitignore not found. Add .docit_ai.yml manually to avoid committing your API key.", :yellow
          return
        end

        content = File.read(gitignore)
        return if content.include?(".docit_ai.yml")

        File.open(gitignore, "a") do |f|
          f.puts "" if content.end_with?("\n") == false
          f.puts "# Docit AI configuration (contains API key)"
          f.puts ".docit_ai.yml"
        end
        say "Added .docit_ai.yml to .gitignore", :green
      end

      def print_instructions
        say ""
        say "Docit AI configured successfully!", :green
        say ""
        say "Docit stores your API key in .docit_ai.yml with restricted file permissions."
        say "Keep that file out of version control."
        say ""
        say "Next steps:"
        say "  rails docit:autodoc                              # document all undocumented endpoints"
        say "  rails docit:autodoc[Api::V1::UsersController]    # document a specific controller"
        say "  DRY_RUN=1 rails docit:autodoc                    # preview without writing files"
        say ""
        say "To reconfigure, run this generator again."
        say ""
      end

      private

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
    end
  end
end

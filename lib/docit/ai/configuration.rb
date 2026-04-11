# frozen_string_literal: true

require "yaml"

module Docit
  module Ai
    class Configuration
      CONFIG_FILE = ".docit_ai.yml"

      PROVIDERS = %w[openai anthropic groq].freeze

      DEFAULT_MODELS = {
        "openai" => "gpt-4o-mini",
        "anthropic" => "claude-haiku-4-5-20251001",
        "groq" => "llama-3.3-70b-versatile"
      }.freeze

      attr_reader :provider, :model, :api_key

      def initialize(provider:, model:, api_key:)
        @provider = provider.to_s
        @model = model.to_s
        @api_key = api_key.to_s
      end

      def valid?
        PROVIDERS.include?(provider) && !model.empty? && !api_key.empty?
      end

      class << self
        def config_path
          Rails.root.join(CONFIG_FILE)
        end

        def configured?
          File.exist?(config_path)
        end

        def load
          raise Error, "AI not configured. Run: rails generate docit:ai_setup" if configured? == false

          data = YAML.safe_load_file(config_path, permitted_classes: [Symbol])
          new(
            provider: data["provider"],
            model: data["model"],
            api_key: data["api_key"]
          )
        end

        def save(provider:, model:, api_key:)
          config = new(provider: provider, model: model, api_key: api_key)
          raise Error, "Invalid configuration" if config.valid? == false

          File.write(config_path, {
            "provider" => config.provider,
            "model" => config.model,
            "api_key" => config.api_key
          }.to_yaml)
          File.chmod(0o600, config_path)

          config
        end
      end
    end
  end
end

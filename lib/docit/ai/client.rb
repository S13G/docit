# frozen_string_literal: true

module Docit
  module Ai
    class Error < Docit::Error; end

    class RateLimitError < Error
      attr_reader :retry_after

      def initialize(message, retry_after: nil)
        @retry_after = retry_after
        super(message)
      end
    end

    # Factory for AI provider clients.
    module Client
      def self.for(config)
        case config.provider
        when "openai"
          OpenaiClient.new(api_key: config.api_key, model: config.model)
        when "anthropic"
          AnthropicClient.new(api_key: config.api_key, model: config.model)
        when "groq"
          GroqClient.new(api_key: config.api_key, model: config.model)
        else
          raise Error, "Unsupported provider: #{config.provider}"
        end
      end
    end
  end
end

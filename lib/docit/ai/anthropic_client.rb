# frozen_string_literal: true

require "net/http"
require "json"
require "uri"

module Docit
  module Ai
    class AnthropicClient
      API_URL = "https://api.anthropic.com/v1/messages"
      API_VERSION = "2023-06-01"

      def initialize(api_key:, model:)
        @api_key = api_key
        @model = model
      end

      def generate(prompt)
        uri = URI(API_URL)
        request = Net::HTTP::Post.new(uri)
        request["x-api-key"] = @api_key
        request["anthropic-version"] = API_VERSION
        request["Content-Type"] = "application/json"
        request.body = {
          model: @model,
          max_tokens: 4096,
          messages: [{ role: "user", content: prompt }]
        }.to_json

        response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true, open_timeout: 15, read_timeout: 60) do |http|
          http.request(request)
        end

        handle_response(response)
      end

      private

      def handle_response(response)
        body = parse_json(response, "Anthropic")

        if response.is_a?(Net::HTTPSuccess) == false
          message = body.dig("error", "message") || "Unknown API error"

          if response.code == "429"
            retry_after = response["Retry-After"]&.to_f
            raise RateLimitError.new("Anthropic rate limit exceeded", retry_after: retry_after)
          end

          raise Error, "Anthropic API error (#{response.code}): #{message}"
        end

        body.dig("content", 0, "text") || raise(Error, "Empty response from Anthropic")
      end

      def parse_json(response, provider_name)
        JSON.parse(response.body)
      rescue JSON::ParserError
        raise Error, "#{provider_name} returned invalid JSON (HTTP #{response.code})"
      end
    end
  end
end

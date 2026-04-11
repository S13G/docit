# frozen_string_literal: true

require "net/http"
require "json"
require "uri"

module Docit
  module Ai
    class GroqClient
      API_URL = "https://api.groq.com/openai/v1/chat/completions"

      def initialize(api_key:, model:)
        @api_key = api_key
        @model = model
      end

      def generate(prompt)
        uri = URI(API_URL)
        request = Net::HTTP::Post.new(uri)
        request["Authorization"] = "Bearer #{@api_key}"
        request["Content-Type"] = "application/json"
        request.body = {
          model: @model,
          messages: [{ role: "user", content: prompt }],
          temperature: 0.2
        }.to_json

        response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true, open_timeout: 15, read_timeout: 60) do |http|
          http.request(request)
        end

        handle_response(response)
      end

      private

      def handle_response(response)
        body = parse_json(response, "Groq")

        if response.is_a?(Net::HTTPSuccess) == false
          message = body.dig("error", "message") || "Unknown API error"
          raise Error, "Groq API error (#{response.code}): #{message}"
        end

        body.dig("choices", 0, "message", "content") || raise(Error, "Empty response from Groq")
      end

      def parse_json(response, provider_name)
        JSON.parse(response.body)
      rescue JSON::ParserError
        raise Error, "#{provider_name} returned invalid JSON (HTTP #{response.code})"
      end
    end
  end
end

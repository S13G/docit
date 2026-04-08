# frozen_string_literal: true

module Docket
  class Configuration
    attr_accessor :title, :version, :description, :base_url

    def initialize
      @title = "API Documentation"
      @version = "1.0.0"
      @description = ""
      @base_url = "/"
      @security_schemes = {}
    end

    def auth(type, **options)
      case type.to_s.downcase
      when "basic"
        @security_schemes[:basic_auth] = {
          type: "http",
          scheme: "basic"
        }
      when "bearer"
        @security_schemes[:bearer_auth] = {
          type: "http",
          scheme: "bearer",
          bearerFormat: options[:bearer_format] || "JWT"
        }
      when "api_key"
        @security_schemes[:api_key] = {
          type: "apiKey",
          name: options[:name] || "X-API-Key",
          in: options[:location] || "header"
        }
      else
        raise ArgumentError, "Unsupported auth type: #{type}"
      end
    end

    def security_schemes
      @security_schemes.dup
    end
  end
end

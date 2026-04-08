# frozen_string_literal: true

module Docket
  # Holds global API documentation settings: metadata, authentication, tags, and servers.
  class Configuration
    attr_accessor :title, :version, :description, :base_url

    def initialize
      @title = "API Documentation"
      @version = "1.0.0"
      @description = ""
      @base_url = "/"
      @security_schemes = {}
      @tags = []
      @servers = []
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

    def tag(name, description: nil)
      entry = { name: name.to_s }
      entry[:description] = description if description
      @tags << entry
    end

    def tags
      @tags.dup
    end

    def server(url, description: nil)
      entry = { url: url.to_s }
      entry[:description] = description if description
      @servers << entry
    end

    def servers
      @servers.dup
    end
  end
end

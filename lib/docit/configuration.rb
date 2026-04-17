# frozen_string_literal: true

module Docit
  # Holds global API documentation settings: metadata, authentication, tags, and servers.
  class Configuration
    SUPPORTED_UIS = %i[scalar swagger].freeze

    attr_accessor :title, :version, :description, :base_url
    attr_reader :default_ui

    def initialize
      @title = "API Documentation"
      @version = "1.0.0"
      @description = "Welcome to the API documentation. Browse the endpoints below to get started."
      @base_url = "/"
      @default_ui = :scalar
      @security_schemes = {}
      @tags = []
      @servers = []
      @license = nil
      @contact = nil
      @terms_of_service = nil
    end

    def default_ui=(value)
      ui = value.to_sym
      unless SUPPORTED_UIS.include?(ui)
        raise ArgumentError, "Unsupported UI: #{value}. Must be one of: #{SUPPORTED_UIS.join(", ")}"
      end

      @default_ui = ui
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

    def license(name:, url: nil)
      entry = { name: name }
      entry[:url] = url if url
      @license = entry
    end

    def license_info
      @license&.dup
    end

    def contact(name: nil, email: nil, url: nil)
      entry = {}
      entry[:name] = name if name
      entry[:email] = email if email
      entry[:url] = url if url
      @contact = entry
    end

    def contact_info
      @contact&.dup
    end

    def terms_of_service(url)
      @terms_of_service = url
    end

    def terms_of_service_url
      @terms_of_service
    end
  end
end

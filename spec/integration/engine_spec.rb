# frozen_string_literal: true

require "spec_helper"

# Boot the dummy Rails app
ENV["RAILS_ENV"] = "test"
require File.expand_path("../dummy/config/environment", __dir__)

RSpec.describe "Docit Engine Integration", type: :request do
  include Rack::Test::Methods

  def app
    Rails.application
  end

  before do
    Docit::Registry.clear!
    Docit.reset_configuration!
    Docit.reset_schemas!
    Docit.configure do |config|
      config.title = "Dummy Test API"
      config.version = "1.0.0"
      config.description = "A test API for Docit gem integration tests"
      config.auth :bearer
    end
  end

  describe "GET /api-docs/spec" do
    before { get "/api-docs/spec" }

    it "returns a valid OpenAPI spec" do
      expect(last_response.status).to eq(200)

      spec = JSON.parse(last_response.body)
      expect(spec["openapi"]).to eq("3.0.3")
      expect(spec["info"]["title"]).to eq("Dummy Test API")
      expect(spec["info"]["version"]).to eq("1.0.0")
    end

    it "includes documented paths" do
      spec = JSON.parse(last_response.body)
      paths = spec["paths"]

      expect(paths).to have_key("/api/v1/auth/register")
      expect(paths).to have_key("/api/v1/auth/login")
      expect(paths).to have_key("/api/v1/users")
      expect(paths).to have_key("/api/v1/users/{id}")
    end

    it "maps correct HTTP methods" do
      spec = JSON.parse(last_response.body)

      expect(spec["paths"]["/api/v1/auth/register"]).to have_key("post")
      expect(spec["paths"]["/api/v1/auth/login"]).to have_key("post")
      expect(spec["paths"]["/api/v1/users"]).to have_key("get")
      expect(spec["paths"]["/api/v1/users/{id}"]).to have_key("get")
    end

    it "includes operation details" do
      spec = JSON.parse(last_response.body)
      login = spec["paths"]["/api/v1/auth/login"]["post"]

      expect(login["summary"]).to eq("Login")
      expect(login["tags"]).to eq(["Authentication"])
      expect(login["requestBody"]["required"]).to be true
    end

    it "includes path parameters" do
      spec = JSON.parse(last_response.body)
      show = spec["paths"]["/api/v1/users/{id}"]["get"]
      id_param = show["parameters"].find { |p| p["name"] == "id" }

      expect(id_param).not_to be_nil
      expect(id_param["in"]).to eq("path")
      expect(id_param["required"]).to be true
    end

    it "includes security schemes" do
      spec = JSON.parse(last_response.body)
      schemes = spec["components"]["securitySchemes"]

      expect(schemes["bearer_auth"]["type"]).to eq("http")
      expect(schemes["bearer_auth"]["scheme"]).to eq("bearer")
    end
  end

  describe "GET /api-docs" do
    before { get "/api-docs" }

    it "returns the Swagger UI page" do
      expect(last_response.status).to eq(200)
      expect(last_response.body).to include("swagger-ui")
      expect(last_response.body).to include("SwaggerUIBundle")
    end

    it "points to the spec URL" do
      expect(last_response.body).to include("/api-docs/spec")
    end
  end
end

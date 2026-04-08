# frozen_string_literal: true

require "docket"

RSpec.describe Docket::SchemaGenerator do
  before do
    Docket::Registry.clear!
    Docket.reset_configuration!

    Docket.configure do |config|
      config.title = "Test API"
      config.version = "2.0.0"
      config.description = "A test API"
      config.auth :bearer
    end
  end

  # Mock RouteInspector since we don't have rails loaded
  before do
    allow(Docket::RouteInspector).to receive(:routes_for)
      .and_return([])

    allow(Docket::RouteInspector).to receive(:routes_for)
      .with("Api::V1::AuthController", "login")
      .and_return([{ path: "/api/v1/auth/login", method: "post" }])

    allow(Docket::RouteInspector).to receive(:routes_for)
      .with("Api::V1::AuthController", "register")
      .and_return([{ path: "/api/v1/auth/register", method: "post" }])
  end

  let(:controller_class) do
    Class.new do
      include Docket::DSL

      def self.name
        "Api::V1::AuthController"
      end

      swagger_doc :login do
        summary "Login"
        description "Authenticates a user and returns tokens"
        tags "Authentication"

        request_body required: true do
          property :email, type: :string, required: true, example: "user@example.com"
          property :password, type: :string, required: true, format: :password
        end

        response 200, "Login successful" do
          property :access_token, type: :string
          property :refresh_token, type: :string
        end

        response 401, "Invalid credentials"

        security :bearer_auth
      end

      swagger_doc :register do
        summary "Register"
        tags "Authentication"

        request_body required: true do
          property :email, type: :string, required: true
          property :password, type: :string, required: true
          property :role, type: :string, enum: %w[customer provider]
        end

        response 201, "Account created" do
          property :user_id, type: :string
        end

        response 409, "Already exists"
      end
    end
  end

  let(:spec) do
    controller_class # trigger class evaluation and registration
    Docket::SchemaGenerator.generate
  end

  describe "info section" do
    it "includes configured metadata" do
      expect(spec[:info][:title]).to eq("Test API")
      expect(spec[:info][:version]).to eq("2.0.0")
      expect(spec[:info][:description]).to eq("A test API")
    end
  end

  describe "openapi version" do
    it "uses 3.0.3" do
      expect(spec[:openapi]).to eq("3.0.3")
    end
  end

  describe "security schemes" do
    it "includes configured schemes in components" do
      schemes = spec[:components][:securitySchemes]
      expect(schemes[:bearer_auth]).to eq({
                                            type: "http",
                                            scheme: "bearer",
                                            bearerFormat: "JWT"
                                          })
    end
  end

  describe "paths" do
    it "generates paths from routes" do
      expect(spec[:paths]).to have_key("/api/v1/auth/login")
      expect(spec[:paths]).to have_key("/api/v1/auth/register")
    end

    it "maps to correct HTTP methods" do
      expect(spec[:paths]["/api/v1/auth/login"]).to have_key("post")
      expect(spec[:paths]["/api/v1/auth/register"]).to have_key("post")
    end
  end

  describe "operation output" do
    let(:login_op) { spec[:paths]["/api/v1/auth/login"]["post"] }

    it "includes summary and description" do
      expect(login_op[:summary]).to eq("Login")
      expect(login_op[:description]).to eq("Authenticates a user and returns tokens")
    end

    it "includes tags" do
      expect(login_op[:tags]).to eq(["Authentication"])
    end

    it "includes security" do
      expect(login_op[:security]).to eq([{ "bearer_auth" => [] }])
    end

    it "builds request body with required fields" do
      body = login_op[:requestBody]
      expect(body[:required]).to be true

      schema = body[:content]["application/json"][:schema]
      expect(schema[:required]).to eq(%w[email password])
      expect(schema[:properties]).to have_key("email")
      expect(schema[:properties]["email"][:example]).to eq("user@example.com")
    end

    it "builds responses" do
      expect(login_op[:responses]).to have_key("200")
      expect(login_op[:responses]).to have_key("401")
      expect(login_op[:responses]["200"][:description]).to eq("Login successful")
      expect(login_op[:responses]["401"][:description]).to eq("Invalid credentials")
    end

    it "includes response properties" do
      props = login_op[:responses]["200"][:content]["application/json"][:schema][:properties]
      expect(props).to have_key("access_token")
      expect(props).to have_key("refresh_token")
    end
  end

  describe "enum support" do
    let(:register_op) { spec[:paths]["/api/v1/auth/register"]["post"] }

    it "includes enum values in properties" do
      schema = register_op[:requestBody][:content]["application/json"][:schema]
      role_prop = schema[:properties]["role"]
      expect(role_prop[:enum]).to eq(%w[customer provider])
    end
  end
end

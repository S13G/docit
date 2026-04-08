# frozen_string_literal: true

require "docit"

RSpec.describe "Nested property support" do
  before do
    Docit::Registry.clear!
    Docit.reset_configuration!

    allow(Docit::RouteInspector).to receive(:routes_for)
      .and_return([])

    allow(Docit::RouteInspector).to receive(:routes_for)
      .with("Api::V1::AuthController", "login")
      .and_return([{ path: "/api/v1/auth/login", method: "post" }])
  end

  let(:controller_class) do
    Class.new do
      include Docit::DSL

      def self.name
        "Api::V1::AuthController"
      end

      swagger_doc :login do
        summary "Login"
        tags "Authentication"

        request_body required: true do
          property :email, type: :string, required: true
          property :password, type: :string, required: true
        end

        response 200, "Login successful" do
          property :status, type: :string, example: "success"
          property :data, type: :object do
            property :user, type: :object do
              property :id, type: :string
              property :email, type: :string
              property :full_name, type: :string
            end
            property :tokens, type: :object do
              property :access, type: :string
              property :refresh, type: :string
            end
          end
        end

        response 422, "Validation errors" do
          property :status, type: :string
          property :errors, type: :array, items: :string
        end
      end
    end
  end

  let(:spec) do
    controller_class
    Docit::SchemaGenerator.generate
  end

  let(:login_op) { spec[:paths]["/api/v1/auth/login"]["post"] }
  let(:success_schema) { login_op[:responses]["200"][:content]["application/json"][:schema] }
  let(:error_schema) { login_op[:responses]["422"][:content]["application/json"][:schema] }

  describe "nested objects" do
    it "generates nested object properties" do
      data_prop = success_schema[:properties]["data"]
      expect(data_prop[:type]).to eq("object")
      expect(data_prop[:properties]).to have_key("user")
      expect(data_prop[:properties]).to have_key("tokens")
    end

    it "generates deeply nested properties" do
      user_prop = success_schema[:properties]["data"][:properties]["user"]
      expect(user_prop[:type]).to eq("object")
      expect(user_prop[:properties]).to have_key("id")
      expect(user_prop[:properties]).to have_key("email")
      expect(user_prop[:properties]).to have_key("full_name")
    end

    it "generates sibling nested objects" do
      tokens_prop = success_schema[:properties]["data"][:properties]["tokens"]
      expect(tokens_prop[:type]).to eq("object")
      expect(tokens_prop[:properties]).to have_key("access")
      expect(tokens_prop[:properties]).to have_key("refresh")
    end
  end

  describe "array types" do
    it "generates array with simple item type" do
      errors_prop = error_schema[:properties]["errors"]
      expect(errors_prop[:type]).to eq("array")
      expect(errors_prop[:items]).to eq({ type: "string" })
    end
  end

  describe "array of objects" do
    before do
      Docit::Registry.clear!

      allow(Docit::RouteInspector).to receive(:routes_for)
        .and_return([])
      allow(Docit::RouteInspector).to receive(:routes_for)
        .with("Api::V1::UsersController", "index")
        .and_return([{ path: "/api/v1/users", method: "get" }])
    end

    let(:users_controller) do
      Class.new do
        include Docit::DSL

        def self.name
          "Api::V1::UsersController"
        end

        swagger_doc :index do
          summary "List users"
          response 200, "Success" do
            property :users, type: :array do
              property :id, type: :string
              property :email, type: :string
              property :role, type: :string, enum: %w[customer provider]
            end
            property :total, type: :integer
          end
        end
      end
    end

    let(:users_spec) do
      users_controller
      Docit::SchemaGenerator.generate
    end

    it "generates array of objects with nested properties" do
      users_prop = users_spec[:paths]["/api/v1/users"]["get"][:responses]["200"][:content]["application/json"][:schema][:properties]["users"]

      expect(users_prop[:type]).to eq("array")
      expect(users_prop[:items][:type]).to eq("object")
      expect(users_prop[:items][:properties]).to have_key("id")
      expect(users_prop[:items][:properties]).to have_key("email")
      expect(users_prop[:items][:properties]["role"][:enum]).to eq(%w[customer provider])
    end
  end
end

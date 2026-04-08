# frozen_string_literal: true

require "docit"

RSpec.describe Docit::Operation do
  let(:operation) { described_class.new(controller: "Api::V1::AuthController", action: :login) }

  describe "#summary" do
    it "sets the summary" do
      operation.summary "Login endpoint"
      expect(operation._summary).to eq("Login endpoint")
    end
  end

  describe "#description" do
    it "sets the description" do
      operation.description "Authenticates a user"
      expect(operation._description).to eq("Authenticates a user")
    end
  end

  describe "#tags" do
    it "sets tags from arguments" do
      operation.tags "Auth", "User"
      expect(operation._tags).to eq(%w[Auth User])
    end

    it "flattens arrays" do
      operation.tags %w[Auth User]
      expect(operation._tags).to eq(%w[Auth User])
    end
  end

  describe "#request_body" do
    it "builds a request body with properties" do
      operation.request_body required: true do
        property :email, type: :string, required: true, example: "admin@example.com"
        property :password, type: :string, required: true, format: :password
      end

      body = operation._request_body
      expect(body.required).to be true
      expect(body.properties.length).to eq(2)
      expect(body.required_properties).to eq(%w[email password])
    end
  end

  describe "#response" do
    it "builds responses with properties" do
      operation.response 200, "Success" do
        property :token, type: :string
        property :user_id, type: :integer
      end

      operation.response 401, "Unauthorized"

      expect(operation._responses.length).to eq(2)
      expect(operation._responses.first.status).to eq(200)
      expect(operation._responses.first.properties.length).to eq(2)
      expect(operation._responses.last.status).to eq(401)
      expect(operation._responses.last.properties).to be_empty
    end
  end

  describe "#parameter" do
    it "adds parameters" do
      operation.parameter :status, location: :query, type: :string, enum: %w[active inactive]

      params = operation._parameters.params
      expect(params.length).to eq(1)
      expect(params.first[:name]).to eq("status")
      expect(params.first[:in]).to eq("query")
      expect(params.first[:schema][:enum]).to eq(%w[active inactive])
    end
  end

  describe "#security" do
    it "adds security schemes" do
      operation.security :bearer_auth
      expect(operation._security).to eq([:bearer_auth])
    end
  end
end

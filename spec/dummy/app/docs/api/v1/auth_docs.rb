# frozen_string_literal: true

module Api
  module V1
    module AuthDocs
      extend Docit::DocFile

      doc :register do
        summary "Register a new user"
        description "Creates a new user account"
        tags "Authentication"

        response 201, "Account created successfully" do
          property :message, type: :string, example: "registered"
        end

        response 500, "Internal server error" do
          property :error, type: :string, example: "Internal server error"
        end
      end

      doc :login do
        summary "Login"
        description "Authenticate a user and return a success message"
        tags "Authentication"
        security :bearer_auth

        request_body required: true do
          property :email, type: :string, required: true, example: "user@example.com"
          property :password, type: :string, required: true, format: :password
        end

        response 200, "Logged in successfully" do
          property :message, type: :string, example: "logged in"
        end

        response 401, "Unauthorized" do
          property :error, type: :string, example: "Invalid credentials"
        end

        response 500, "Internal server error" do
          property :error, type: :string, example: "Internal server error"
        end
      end
    end
  end
end

# frozen_string_literal: true

module Api
  module V1
    module AuthDocs
      extend Docket::DocFile

      doc :register do
        summary "Register a new user"
        description "Creates a customer account and sends verification email"
        tags "Authentication"

        request_body required: true do
          property :email, type: :string, required: true, example: "user@example.com"
          property :password, type: :string, required: true, format: :password
          property :full_name, type: :string, required: true, example: "John Doe"
          property :role, type: :string, enum: %w[customer provider]
        end

        response 201, "Account created successfully" do
          property :user_id, type: :string, example: "123e4567-e89b-12d3-a456-426614174000"
          property :email, type: :string, example: "user@example.com"
          property :full_name, type: :string, example: "John Doe"
        end

        response 409, "Account already exists" do
          property :error, type: :string, example: "Account already exists"
        end

        response 422, "Validation error" do
          property :errors, type: :object do
            property :email, type: :array, items: :string
            property :password, type: :array, items: :string
          end
        end
      end

      doc :login do
        summary "Login"
        description "Authenticates a user and returns JWT tokens"
        tags "Authentication"

        request_body required: true do
          property :email, type: :string, required: true, example: "user@example.com"
          property :password, type: :string, required: true, format: :password
        end

        response 200, "Login successful" do
          property :token, type: :object do
            property :access, type: :string, example: "eyJ0eXAi..."
            property :refresh, type: :string, example: "eyJ0eXAi..."
          end
          property :user, type: :object do
            property :user_id, type: :string, example: "123e4567-e89b-12d3-a456-426614174000"
            property :email, type: :string, example: "user@example.com"
            property :full_name, type: :string, example: "John Doe"
          end
        end

        response 401, "Invalid credentials" do
          property :error, type: :string, example: "Invalid password"
        end

        response 404, "User not found" do
          property :error, type: :string, example: "User not found"
        end

        security :bearer_auth
      end
    end
  end
end

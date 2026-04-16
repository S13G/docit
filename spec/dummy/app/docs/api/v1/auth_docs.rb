# frozen_string_literal: true

module Api
  module V1
    module AuthDocs
      extend Docit::DocFile

      doc :register do
        summary "Register a new user"
        description "Creates a new user account in the system"
        tags "Authentication"

        request_body required: true do
          property :email, type: :string, required: true, example: "user@example.com"
          property :password, type: :string, required: true, example: "secure_password_123"
          property :full_name, type: :string, required: true, example: "John Doe"
        end

        response 201, "User registered successfully" do
          property :message, type: :string, example: "registered"
        end

        response 422, "Validation error" do
          property :errors, type: :object do
            property :email, type: :array
            property :password, type: :array
          end
        end
      end

      doc :login do
        summary "User login"
        description "Authenticates a user with email and password credentials"
        tags "Authentication"

        request_body required: true do
          property :email, type: :string, required: true, example: "user@example.com"
          property :password, type: :string, required: true, example: "securepassword123"
        end

        response 200, "Login successful" do
          property :message, type: :string, example: "logged in"
          property :token, type: :string, example: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
          property :user, type: :object do
            property :id, type: :string, example: "123e4567-e89b-12d3-a456-426614174000"
            property :email, type: :string, example: "user@example.com"
          end
        end

        response 401, "Unauthorized" do
          property :error, type: :string, example: "Invalid email or password"
        end

        response 422, "Validation error" do
          property :errors, type: :object do
            property :email, type: :array
            property :password, type: :array
          end
        end
      end
    end
  end
end

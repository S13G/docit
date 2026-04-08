# frozen_string_literal: true

module Api
  module V1
    class AuthController < ApplicationController
      swagger_doc :register do
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
          property :email, type: :string
          property :full_name, type: :string
        end

        response 409, "Account already exists"
        response 422, "Validation error"
      end
      def register
        render json: { message: "registered" }, status: :created
      end

      swagger_doc :login do
        summary "Login"
        description "Authenticates a user and returns JWT tokens"
        tags "Authentication"

        request_body required: true do
          property :email, type: :string, required: true
          property :password, type: :string, required: true
        end

        response 200, "Login successful" do
          property :access_token, type: :string
          property :refresh_token, type: :string
        end

        response 401, "Invalid credentials"

        security :bearer_auth
      end
      def login
        render json: { message: "logged in" }, status: :ok
      end
    end
  end
end

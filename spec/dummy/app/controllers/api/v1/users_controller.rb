# frozen_string_literal: true

module Api
  module V1
    class UsersController < ApplicationController
      swagger_doc :index do
        summary "List all users"
        tags "Users"

        parameter :page, location: :query, type: :integer, description: "Page number"
        parameter :per_page, location: :query, type: :integer, description: "Items per page"

        response 200, "Success" do
          property :users, type: :array
          property :total, type: :integer
        end
      end
      def index
        render json: { users: [], total: 0 }
      end

      swagger_doc :show do
        summary "Get a user by ID"
        tags "Users"

        parameter :id, location: :path, type: :string, required: true, description: "User ID"

        response 200, "Success" do
          property :id, type: :string
          property :email, type: :string
          property :full_name, type: :string
        end

        response 404, "User not found"
      end
      def show
        render json: { id: params[:id], email: "test@example.com", full_name: "Test User" }
      end
    end
  end
end

# frozen_string_literal: true

module Api
  module V1
    module UsersDocs
      extend Docit::DocFile

      doc :index do
        summary "List all users"
        description "Retrieves a paginated list of all users in the system"
        tags "Users"
        security :bearer_auth

        parameter :page, location: :query, type: :integer, required: false, description: "Page number for pagination"
        parameter :per_page, location: :query, type: :integer, required: false, description: "Number of users per page"

        response 200, "Users retrieved successfully" do
          property :users, type: :array do
            property :id, type: :string, example: "123e4567-e89b-12d3-a456-426614174000"
            property :email, type: :string, example: "user@example.com"
            property :full_name, type: :string, example: "John Doe"
          end
          property :total, type: :integer, example: 42
        end

        response 401, "Unauthorized" do
          property :error, type: :string, example: "Unauthorized"
        end
      end

      doc :show do
        summary "Retrieve a user by ID"
        description "Fetches a single user's details including email and full name"
        tags "Users"

        parameter :id, location: :path, type: :string, required: true, description: "User ID"

        response 200, "User retrieved successfully" do
          property :id, type: :string, example: "123e4567-e89b-12d3-a456-426614174000"
          property :email, type: :string, example: "test@example.com"
          property :full_name, type: :string, example: "Test User"
        end

        response 404, "User not found" do
          property :error, type: :string, example: "User not found"
        end
      end
    end
  end
end

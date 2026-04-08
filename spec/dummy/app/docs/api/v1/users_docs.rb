# frozen_string_literal: true

module Api
  module V1
    module UsersDocs
      extend Docket::DocFile

      doc :index do
        summary "List all users"
        description "Returns a paginated list of all users"
        tags "Users"

        parameter :page, location: :query, type: :integer, description: "Page number"
        parameter :per_page, location: :query, type: :integer, description: "Items per page"

        response 200, "Users retrieved successfully" do
          property :users, type: :array do
            property :id, type: :string, example: "123e4567-e89b-12d3-a456-426614174000"
            property :email, type: :string, example: "user@example.com"
            property :full_name, type: :string, example: "John Doe"
            property :role, type: :string, enum: %w[customer provider]
          end
          property :total, type: :integer, example: 42
          property :page, type: :integer, example: 1
        end
      end

      doc :show do
        summary "Get a user by ID"
        description "Returns the details of a specific user"
        tags "Users"

        parameter :id, location: :path, type: :string, required: true, description: "User ID (UUID)"

        response 200, "User found" do
          property :id, type: :string, example: "123e4567-e89b-12d3-a456-426614174000"
          property :email, type: :string, example: "user@example.com"
          property :full_name, type: :string, example: "John Doe"
          property :role, type: :string, enum: %w[customer provider]
          property :created_at, type: :string, format: "date-time"
        end

        response 404, "User not found" do
          property :error, type: :string, example: "User not found"
        end
      end
    end
  end
end

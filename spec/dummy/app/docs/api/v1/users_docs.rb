# frozen_string_literal: true

module Api
  module V1
    module UsersDocs
      extend Docit::DocFile

      doc :index do
        summary "Retrieve a list of users"
        description "Returns a list of users with pagination information"
        tags "Users"

        response 200, "Users retrieved successfully" do
          property :users, type: :array do
            property :id, type: :string, example: "123e4567-e89b-12d3-a456-426614174000"
            property :email, type: :string, example: "user@example.com"
            property :full_name, type: :string, example: "John Doe"
          end
          property :total, type: :integer, example: 10
        end

        response 500, "Internal server error" do
          property :error, type: :string, example: "Internal server error"
        end
      end

      doc :show do
        summary "Retrieve a user by ID"
        description "Fetches a user's details by their unique identifier"
        tags "Users"

        parameter :id, location: :path, type: :string, required: true, description: "User's unique identifier"

        response 200, "User found" do
          property :id, type: :string, example: "123e4567-e89b-12d3-a456-426614174000"
          property :email, type: :string, example: "user@example.com"
          property :full_name, type: :string, example: "John Doe"
        end

        response 404, "User not found" do
          property :error, type: :string, example: "User not found"
        end
      end
    end
  end
end

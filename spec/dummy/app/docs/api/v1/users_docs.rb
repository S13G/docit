# frozen_string_literal: true

# Shared User schema, referenced via `schema ref: :User` below. Defining it once
# here keeps the docs DRY and produces `uses_schema` edges on the System Map.
Docit.define_schema :User do
  property :id, type: :integer, read_only: true, example: 1
  property :email, type: :string, example: "user@example.com"
  property :full_name, type: :string, nullable: true, example: "John Doe"
end

module Api
  module V1
    module UsersDocs
      extend Docit::DocFile

      doc :index do
        summary "Retrieve a list of users"
        description "Returns a list of users and the total count"
        tags "Users"

        response 200, "Users retrieved successfully" do
          # Demonstrates response headers (e.g. rate limiting).
          header "X-Total-Count", type: :integer, description: "Total users available"
          header "X-RateLimit-Remaining", type: :integer, description: "Requests left in the window"

          property :users, type: :array do
            property :id, type: :integer, read_only: true, example: 1
            property :email, type: :string, example: "user@example.com"
            property :full_name, type: :string, nullable: true, example: "John Doe"
          end
          property :total, type: :integer, example: 2
        end

        response 500, "Internal server error" do
          property :error, type: :string, example: "Internal server error"
        end
      end

      doc :show do
        summary "Retrieve a user by ID"
        description "Returns a user's details"
        tags "Users"

        parameter :id, location: :path, type: :integer, required: true, description: "User ID"

        # References the shared schema instead of repeating the properties.
        response 200, "User found" do
          schema ref: :User
        end

        response 404, "Not found" do
          property :error, type: :string, example: "User not found"
        end
      end
    end
  end
end

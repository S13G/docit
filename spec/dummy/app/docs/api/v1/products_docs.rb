# frozen_string_literal: true

module Api
  module V1
    module ProductsDocs
      extend Docit::DocFile

      doc :index do
        summary "List all products"
        description "Retrieves a paginated list of all available products with their details"
        tags "Products"

        parameter :page, location: :query, type: :integer, required: false, description: "Page number for pagination"

        response 200, "Products retrieved successfully" do
          property :products, type: :array do
            property :id, type: :integer, example: 1
            property :name, type: :string, example: "Widget"
            property :price, type: :integer, example: 29.99
            property :category, type: :string, example: "tools"
            property :in_stock, type: :boolean, example: true
          end
          property :total, type: :integer, example: 2
          property :page, type: :integer, example: 1
        end
      end

      doc :create do
        summary "Create a new product"
        description "Creates a new product with the provided details and returns the created product"
        tags "Products"

        request_body required: true do
          property :name, type: :string, required: true, example: "Widget"
          property :price, type: :integer, required: true, example: 2999
          property :category, type: :string, required: true, example: "tools"
        end

        response 201, "Product created successfully" do
          property :id, type: :string, example: "123e4567-e89b-12d3-a456-426614174000"
          property :name, type: :string, example: "Widget"
          property :price, type: :integer, example: 2999
          property :category, type: :string, example: "tools"
        end

        response 422, "Validation error" do
          property :errors, type: :object do
            property :name, type: :array
            property :price, type: :array
            property :category, type: :array
          end
        end
      end

      doc :show do
        summary "Retrieve a product"
        description "Fetches details of a specific product by ID"
        tags "Products"

        parameter :id, location: :path, type: :string, required: true, description: "Product ID"

        response 200, "Product details retrieved successfully" do
          property :id, type: :string, example: "1"
          property :name, type: :string, example: "Widget"
          property :description, type: :string, example: "A useful widget"
          property :price, type: :integer, example: 29.99
          property :category, type: :string, example: "tools"
          property :in_stock, type: :boolean, example: true
          property :created_at, type: :string, example: "2024-01-15T10:30:00Z"
        end

        response 404, "Product not found" do
          property :error, type: :string, example: "Product not found"
        end
      end

      doc :update do
        summary "Update a product"
        description "Updates an existing product with the provided fields"
        tags "Products"

        parameter :id, location: :path, type: :string, required: true, description: "Product ID"

        request_body required: true do
          property :name, type: :string, required: false, example: "Updated Widget"
          property :price, type: :string, required: false, example: "39.99"
        end

        response 200, "Product updated successfully" do
          property :id, type: :string, example: "1"
          property :name, type: :string, example: "Updated Widget"
          property :price, type: :string, example: "39.99"
          property :updated_at, type: :string, example: "2024-01-15T10:30:00Z"
        end

        response 404, "Product not found" do
          property :error, type: :string, example: "Product not found"
        end

        response 422, "Validation error" do
          property :errors, type: :object do
            property :name, type: :array
            property :price, type: :array
          end
        end
      end

      doc :destroy do
        summary "Delete a product"
        description "Removes a product from the catalog by ID"
        tags "Products"
        security :bearer_auth

        parameter :id, location: :path, type: :string, required: true, description: "Product ID"

        response 204, "Product deleted successfully"

        response 404, "Product not found" do
          property :error, type: :string, example: "Product not found"
        end

        response 401, "Unauthorized" do
          property :error, type: :string, example: "Unauthorized"
        end
      end
    end
  end
end

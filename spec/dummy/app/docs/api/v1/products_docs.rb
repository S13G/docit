# frozen_string_literal: true

module Api
  module V1
    module ProductsDocs
      extend Docit::DocFile

      doc :index do
        summary "Retrieve a list of products"
        description "Returns a paginated list of products with their details"
        tags "Products"

        parameter :page, location: :query, type: :integer, required: false, description: "Page number for pagination"

        response 200, "Products retrieved successfully" do
          property :products, type: :array do
            property :id, type: :integer, example: 1
            property :name, type: :string, example: "Widget"
            property :price, type: :number, example: 29.99
            property :category, type: :string, example: "tools"
            property :in_stock, type: :boolean, example: true
          end
          property :total, type: :integer, example: 2
          property :page, type: :integer, example: 1
        end

        response 500, "Internal server error" do
          property :error, type: :string, example: "Internal server error"
        end
      end

      doc :create do
        summary "Create a new product"
        description "Creates a new product with the provided details"
        tags "Products"

        request_body required: true do
          property :name, type: :string, required: true, example: "New Product"
          property :price, type: :number, required: true, example: 19.99
          property :category, type: :string, required: true, example: "electronics"
        end

        response 201, "Product created successfully" do
          property :id, type: :string, example: "123e4567-e89b-12d3-a456-426614174000"
          property :name, type: :string, example: "New Product"
          property :price, type: :number, example: 19.99
          property :category, type: :string, example: "electronics"
        end

        response 422, "Validation error" do
          property :errors, type: :object do
            property :name, type: :array, items: :string
            property :price, type: :array, items: :string
            property :category, type: :array, items: :string
          end
        end
      end

      doc :show do
        summary "Retrieve a product by ID"
        description "Returns a product with the given ID"
        tags "Products"

        parameter :id, location: :path, type: :string, required: true, description: "Product ID"

        response 200, "Product found" do
          property :id, type: :string, example: "1"
          property :name, type: :string, example: "Widget"
          property :description, type: :string, example: "A useful widget"
          property :price, type: :number, example: 29.99
          property :category, type: :string, example: "tools"
          property :in_stock, type: :boolean, example: true
          property :created_at, type: :string, example: "2022-01-01T12:00:00Z"
        end

        response 404, "Product not found" do
          property :error, type: :string, example: "Product not found"
        end
      end

      doc :update do
        summary "Update a product"
        description "Updates the details of a product"
        tags "Products"

        parameter :id, location: :path, type: :string, required: true

        request_body required: true do
          property :name, type: :string, example: "Updated Widget"
          property :price, type: :number, example: 39.99
        end

        response 200, "Product updated successfully" do
          property :id, type: :string, example: "123e4567-e89b-12d3-a456-426614174000"
          property :name, type: :string, example: "Updated Widget"
          property :price, type: :number, example: 39.99
          property :updated_at, type: :string, example: "2023-03-01T12:00:00.000Z"
        end

        response 404, "Product not found" do
          property :error, type: :string, example: "Product not found"
        end

        response 422, "Validation error" do
          property :errors, type: :object do
            property :name, type: :array, items: :string
            property :price, type: :array, items: :string
          end
        end
      end

      doc :destroy do
        summary "Delete a product"
        description "Removes a product by ID"
        tags "Products"
        security :bearer_auth

        parameter :id, location: :path, type: :string, required: true, description: "Product ID"

        response 204, "Product deleted successfully"
        response 404, "Product not found" do
          property :error, type: :string, example: "Product not found"
        end
        response 422, "Validation error" do
          property :errors, type: :object do
            property :id, type: :array, items: :string
          end
        end
      end
    end
  end
end

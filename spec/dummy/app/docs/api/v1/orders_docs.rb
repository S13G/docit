# frozen_string_literal: true

module Api
  module V1
    module OrdersDocs
      extend Docit::DocFile

      doc :cancel do
        summary "Cancel an order"
        description "Updates the status of an order to cancelled"
        tags "Orders"

        parameter :id, location: :path, type: :string, required: true, description: "Order ID"

        response 200, "Order cancelled successfully" do
          property :id, type: :string, example: "123e4567-e89b-12d3-a456-426614174000"
          property :status, type: :string, example: "cancelled"
          property :cancelled_at, type: :string, example: "2023-03-01T12:00:00.000Z"
        end

        response 404, "Order not found" do
          property :error, type: :string, example: "Order not found"
        end

        response 422, "Validation error" do
          property :errors, type: :object do
            property :id, type: :array, items: :string
          end
        end
      end

      doc :index do
        summary "Retrieve a list of orders"
        description "Returns a list of orders with pagination information"
        tags "Orders"

        response 200, "Orders retrieved successfully" do
          property :orders, type: :array do
            property :id, type: :integer, example: 1
            property :user_id, type: :string, example: "abc-123"
            property :status, type: :string, example: "pending"
            property :total, type: :float, example: 79.98
          end
          property :total, type: :integer, example: 1
        end

        response 500, "Internal server error" do
          property :error, type: :string, example: "Internal server error"
        end
      end

      doc :create do
        summary "Create a new order"
        description "Creates a new order with the given total"
        tags "Orders"

        request_body required: true do
          property :total, type: :float, required: true, example: 79.98
        end

        response 201, "Order created successfully" do
          property :id, type: :string, example: "123e4567-e89b-12d3-a456-426614174000"
          property :status, type: :string, example: "pending"
          property :total, type: :float, example: 79.98
        end

        response 422, "Validation error" do
          property :errors, type: :object do
            property :total, type: :array, items: :string
          end
        end
      end

      doc :show do
        summary "Retrieve an order by ID"
        description "Fetches an order with the specified ID"
        tags "Orders"

        parameter :id, location: :path, type: :string, required: true, description: "Order ID"

        response 200, "Order retrieved successfully" do
          property :id, type: :string, example: "123e4567-e89b-12d3-a456-426614174000"
          property :user_id, type: :string, example: "abc-123"
          property :status, type: :string, example: "shipped"
          property :total, type: :number, example: 79.98
          property :items, type: :array do
            property :product_id, type: :integer, example: 1
            property :quantity, type: :integer, example: 2
            property :unit_price, type: :number, example: 29.99
          end
          property :shipping_address, type: :object do
            property :street, type: :string, example: "123 Main St"
            property :city, type: :string, example: "Springfield"
            property :state, type: :string, example: "IL"
            property :zip, type: :string, example: "62704"
          end
          property :created_at, type: :string, example: "2022-01-01T12:00:00Z"
        end

        response 404, "Order not found" do
          property :error, type: :string, example: "Order not found"
        end
      end
    end
  end
end

# frozen_string_literal: true

module Api
  module V1
    module OrdersDocs
      extend Docit::DocFile

      doc :cancel do
        summary "Cancel an order"
        description "Cancels an existing order by ID and returns the updated order status"
        tags "Orders"
        security :bearer_auth

        parameter :id, location: :path, type: :string, required: true, description: "Order ID"

        response 200, "Order cancelled successfully" do
          property :id, type: :string, example: "550e8400-e29b-41d4-a716-446655440000"
          property :status, type: :string, example: "cancelled"
          property :cancelled_at, type: :string, example: "2024-01-15T10:30:00Z"
        end

        response 404, "Order not found" do
          property :error, type: :string, example: "Order not found"
        end

        response 422, "Order cannot be cancelled" do
          property :error, type: :string, example: "Order has already been shipped"
        end
      end

      doc :index do
        summary "List all orders"
        description "Retrieves a paginated list of all orders"
        tags "Orders"
        security :bearer_auth

        parameter :page, location: :query, type: :integer, required: false, description: "Page number for pagination"
        parameter :per_page, location: :query, type: :integer, required: false, description: "Number of orders per page"

        response 200, "Orders retrieved successfully" do
          property :orders, type: :array do
            property :id, type: :integer, example: 1
            property :user_id, type: :string, example: "abc-123"
            property :status, type: :string, enum: %w[pending shipped delivered cancelled], example: "pending"
            property :total, type: :integer, example: 79.98
          end
          property :total, type: :integer, example: 1
        end

        response 401, "Unauthorized" do
          property :error, type: :string, example: "Unauthorized"
        end
      end

      doc :create do
        summary "Create a new order"
        description "Creates a new order with the provided details and returns the created order"
        tags "Orders"
        security :bearer_auth

        request_body required: true do
          property :total, type: :integer, required: true, example: 79.98
        end

        response 201, "Order created successfully" do
          property :id, type: :string, example: "550e8400-e29b-41d4-a716-446655440000"
          property :status, type: :string, example: "pending"
          property :total, type: :integer, example: 79.98
        end

        response 422, "Validation error" do
          property :errors, type: :object do
            property :total, type: :array
          end
        end
      end

      doc :show do
        summary "Retrieve an order"
        description "Fetches details of a specific order including items and shipping address"
        tags "Orders"
        security :bearer_auth

        parameter :id, location: :path, type: :string, required: true, description: "Order ID"

        response 200, "Order retrieved successfully" do
          property :id, type: :string, example: "550e8400-e29b-41d4-a716-446655440000"
          property :user_id, type: :string, example: "abc-123"
          property :status, type: :string, enum: %w[pending shipped cancelled], example: "shipped"
          property :total, type: :integer, example: 7998
          property :items, type: :array do
            property :product_id, type: :integer, example: 1
            property :quantity, type: :integer, example: 2
            property :unit_price, type: :integer, example: 2999
          end
          property :shipping_address, type: :object do
            property :street, type: :string, example: "123 Main St"
            property :city, type: :string, example: "Springfield"
            property :state, type: :string, example: "IL"
            property :zip, type: :string, example: "62704"
          end
          property :created_at, type: :string, example: "2024-01-15T10:30:00Z"
        end

        response 404, "Order not found" do
          property :error, type: :string, example: "Order not found"
        end

        response 401, "Unauthorized" do
          property :error, type: :string, example: "Unauthorized"
        end
      end
    end
  end
end

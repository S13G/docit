# frozen_string_literal: true

module Api
  module V1
    class OrdersController < ApplicationController
      use_docs Api::V1::OrdersDocs

      def index
        render json: {
          orders: [
            { id: 1, user_id: "abc-123", status: "pending", total: 79.98 }
          ],
          total: 1
        }
      end

      def show
        render json: {
          id: params[:id],
          user_id: "abc-123",
          status: "shipped",
          total: 79.98,
          items: [
            { product_id: 1, quantity: 2, unit_price: 29.99 },
            { product_id: 2, quantity: 1, unit_price: 19.99 }
          ],
          shipping_address: {
            street: "123 Main St",
            city: "Springfield",
            state: "IL",
            zip: "62704"
          },
          created_at: Time.current
        }
      end

      def create
        render json: {
          id: SecureRandom.uuid,
          status: "pending",
          total: params[:total]
        }, status: :created
      end

      def cancel
        render json: {
          id: params[:id],
          status: "cancelled",
          cancelled_at: Time.current
        }
      end
    end
  end
end

# frozen_string_literal: true

module Api
  module V1
    class ProductsController < ApplicationController
      use_docs Api::V1::ProductsDocs

      def index
        render json: {
          products: [
            { id: 1, name: "Widget", price: 29.99, category: "tools", in_stock: true },
            { id: 2, name: "Gadget", price: 49.99, category: "electronics", in_stock: false }
          ],
          total: 2,
          page: params[:page] || 1
        }
      end

      def show
        render json: {
          id: params[:id],
          name: "Widget",
          description: "A useful widget",
          price: 29.99,
          category: "tools",
          in_stock: true,
          created_at: Time.current
        }
      end

      def create
        render json: {
          id: SecureRandom.uuid,
          name: params[:name],
          price: params[:price],
          category: params[:category]
        }, status: :created
      end

      def update
        render json: {
          id: params[:id],
          name: params[:name],
          price: params[:price],
          updated_at: Time.current
        }
      end

      def destroy
        head :no_content
      end
    end
  end
end

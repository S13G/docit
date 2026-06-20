# frozen_string_literal: true

module Api
  module V1
    class ProductsController < ApplicationController
      use_docs Api::V1::ProductsDocs

      def index
        products = Product.order(:id)
        render json: {
          products: products.map { |product| product_json(product) },
          total: products.count,
          page: (params[:page] || 1).to_i
        }
      end

      def show
        product = Product.find_by(id: params[:id])
        return render(json: { error: "Product not found" }, status: :not_found) unless product

        render json: product_json(product).merge(
          description: product.description,
          created_at: product.created_at
        )
      end

      def create
        product = Product.new(product_params)
        return render(json: { errors: product.errors.full_messages }, status: :unprocessable_entity) unless product.save

        render json: product_json(product), status: :created
      end

      def update
        product = Product.find_by(id: params[:id])
        return render(json: { error: "Product not found" }, status: :not_found) unless product

        if product.update(product_params)
          render json: product_json(product).merge(updated_at: product.updated_at)
        else
          render json: { errors: product.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        product = Product.find_by(id: params[:id])
        return render(json: { error: "Product not found" }, status: :not_found) unless product

        product.destroy
        head :no_content
      end

      private

      def product_params
        params.permit(:name, :description, :price, :category, :in_stock)
      end

      def product_json(product)
        {
          id: product.id,
          name: product.name,
          price: product.price,
          category: product.category,
          in_stock: product.in_stock
        }
      end
    end
  end
end

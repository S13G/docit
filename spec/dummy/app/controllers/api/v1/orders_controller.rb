# frozen_string_literal: true

module Api
  module V1
    class OrdersController < ApplicationController
      use_docs Api::V1::OrdersDocs

      def index
        orders = Order.order(:id)
        render json: {
          orders: orders.map { |order| order_summary_json(order) },
          total: orders.count
        }
      end

      def show
        order = Order.includes(:order_items).find_by(id: params[:id])
        return render(json: { error: "Order not found" }, status: :not_found) unless order

        render json: order_summary_json(order).merge(
          items: order.order_items.map { |item| item_json(item) },
          created_at: order.created_at
        )
      end

      def create
        order = Order.new(user_id: params[:user_id], total: params[:total] || 0)
        return render(json: { errors: order.errors.full_messages }, status: :unprocessable_entity) unless order.save

        render json: order_summary_json(order), status: :created
      end

      def cancel
        order = Order.find_by(id: params[:id])
        return render(json: { error: "Order not found" }, status: :not_found) unless order

        order.cancel!
        render json: order_summary_json(order).merge(cancelled_at: order.cancelled_at)
      end

      private

      def order_summary_json(order)
        { id: order.id, user_id: order.user_id, status: order.status, total: order.total }
      end

      def item_json(item)
        { product_id: item.product_id, quantity: item.quantity, unit_price: item.unit_price }
      end
    end
  end
end

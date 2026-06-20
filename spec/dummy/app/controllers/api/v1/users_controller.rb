# frozen_string_literal: true

module Api
  module V1
    class UsersController < ApplicationController
      use_docs Api::V1::UsersDocs

      def index
        users = User.order(:id)
        render json: {
          users: users.map { |user| user_json(user) },
          total: users.count
        }
      end

      def show
        user = User.find_by(id: params[:id])
        return render(json: { error: "User not found" }, status: :not_found) unless user

        render json: user_json(user)
      end

      private

      def user_json(user)
        { id: user.id, email: user.email, full_name: user.full_name }
      end
    end
  end
end

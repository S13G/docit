# frozen_string_literal: true

module Api
  module V1
    class AuthController < ApplicationController
      use_docs Api::V1::AuthDocs

      def register
        user = User.find_or_create_by(email: params[:email]) do |u|
          u.full_name = params[:full_name]
        end
        return render(json: { errors: user.errors.full_messages }, status: :unprocessable_entity) unless user.persisted?

        render json: { message: "registered", user_id: user.id }, status: :created
      end

      def login
        user = User.find_by(email: params[:email])
        return render(json: { error: "Invalid credentials" }, status: :unauthorized) unless user

        render json: { message: "logged in", user_id: user.id }, status: :ok
      end
    end
  end
end

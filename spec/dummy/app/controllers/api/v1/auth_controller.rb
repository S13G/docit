# frozen_string_literal: true

module Api
  module V1
    class AuthController < ApplicationController
      use_docs Api::V1::AuthDocs

      def register
        render json: { message: "registered" }, status: :created
      end

      def login
        render json: { message: "logged in" }, status: :ok
      end
    end
  end
end

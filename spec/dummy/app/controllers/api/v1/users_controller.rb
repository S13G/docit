# frozen_string_literal: true

module Api
  module V1
    class UsersController < ApplicationController
      use_docs Api::V1::UsersDocs

      def index
        render json: { users: [], total: 0 }
      end

      def show
        render json: { id: params[:id], email: "test@example.com", full_name: "Test User" }
      end
    end
  end
end

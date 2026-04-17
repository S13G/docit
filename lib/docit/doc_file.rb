# frozen_string_literal: true

module Docit
  # DocFile lets you define API documentation in separate files,
  # keeping your controllers clean. Extend any module with DocFile,
  # then use `doc :action_name do ... end` to define docs.
  #
  # Usage:
  #
  #   # app/docs/users_docs.rb
  #   module UsersDocs
  #     extend Docit::DocFile
  #
  #     doc :index do
  #       summary "List users"
  #       tags "Users"
  #       response 200, "Users retrieved"
  #     end
  #
  #     doc :create do
  #       summary "Create a user"
  #       tags "Users"
  #       request_body required: true do
  #         property :email, type: :string, required: true
  #       end
  #       response 201, "User created"
  #     end
  #   end
  #
  #   # app/controllers/users_controller.rb
  #   class UsersController < ApplicationController
  #     use_docs UsersDocs
  #
  #     def index; end
  #     def create; end
  #   end
  #
  module DocFile
    def self.extended(base)
      base.instance_variable_set(:@_docs, {})
    end

    # The block receives the same DSL as doc_for.
    def doc(action, &block)
      @_docs[action.to_sym] = block
    end

    def [](action)
      @_docs[action.to_sym]
    end

    def actions
      @_docs.keys
    end
  end
end

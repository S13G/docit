# frozen_string_literal: true

module Docit
  module Ai
    class PromptBuilder
      DSL_REFERENCE = <<~DSL
        Available DSL methods inside a `doc :action_name do ... end` block:
          summary "Short description"
          description "Detailed description"
          tags "TagName"
          deprecated value: true
          security :bearer_auth

          parameter :name, location: :query|:path|:header, type: :string|:integer|:boolean, required: true/false, description: "..."
          parameter :id, location: :path, type: :string, required: true

          request_body required: true do
            property :field, type: :string|:integer|:boolean|:array|:object|:file, required: true/false, example: "value"
            property :field, type: :string, enum: %w[option1 option2]
            property :nested, type: :object do
              property :child, type: :string
            end
            property :items, type: :array do
              property :id, type: :string
            end
          end

          response 200, "Description" do
            property :field, type: :string, example: "value"
            property :nested, type: :object do
              property :child, type: :string
            end
          end
          response 404, "Not found" do
            property :error, type: :string, example: "Not found"
          end
      DSL

      EXAMPLE_DOC = <<~EXAMPLE
        doc :register do
          summary "Register a new user"
          description "Creates a customer account and sends verification email"
          tags "Authentication"

          request_body required: true do
            property :email, type: :string, required: true, example: "user@example.com"
            property :password, type: :string, required: true, format: :password
            property :full_name, type: :string, required: true, example: "John Doe"
            property :role, type: :string, enum: %w[customer provider]
          end

          response 201, "Account created successfully" do
            property :user_id, type: :string, example: "123e4567-e89b-12d3-a456-426614174000"
            property :email, type: :string, example: "user@example.com"
          end

          response 422, "Validation error" do
            property :errors, type: :object do
              property :email, type: :array, items: :string
            end
          end
        end
      EXAMPLE

      def initialize(gap:)
        @gap = gap
      end

      def build
        <<~PROMPT
          You are generating Docit DSL documentation for a Ruby on Rails API endpoint.

          #{DSL_REFERENCE}

          Here is a complete example of a well-documented endpoint:
          #{EXAMPLE_DOC}

          Now generate documentation for:
          - Controller: #{@gap[:controller]}
          - Action: #{@gap[:action]}
          - HTTP method: #{@gap[:method].upcase}
          - Path: #{@gap[:path]}

          Controller source code:
          ```ruby
          #{controller_source}
          ```

          Rules:
          - Output ONLY the `doc :#{@gap[:action]} do ... end` block
          - No module wrapper, no explanation, no markdown fences
          - Infer parameters from the path (e.g., {id} → path parameter)
          - Infer request body from params usage in the controller
          - Infer response structure from render calls
          - Use realistic examples
          - Include appropriate error responses
          - Use the controller name to determine appropriate tags
        PROMPT
      end

      def source_available?
        path = controller_file_path
        path && File.exist?(path)
      end

      private

      def controller_source
        path = controller_file_path
        return "# Source not available" if path && File.exist?(path) == false
        return "# Source not available" if path.nil?

        File.read(path)
      end

      def controller_file_path
        return nil if defined?(Rails) == false || Rails.respond_to?(:root) == false || Rails.root.nil?

        relative = @gap[:controller].underscore
        Rails.root.join("app", "controllers", "#{relative}.rb").to_s
      end
    end
  end
end

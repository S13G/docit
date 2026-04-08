# frozen_string_literal: true

Docit.configure do |config|
  # The title shown in Swagger UI
  config.title = "<%= Rails.application.class.module_parent_name rescue 'My API' %>"

  # API version
  config.version = "1.0.0"

  # Description shown in Swagger UI
  config.description = "API documentation powered by Docit"

  # Authentication scheme (options: :bearer, :basic, :api_key)
  # config.auth :bearer

  # For API key auth:
  # config.auth :api_key, name: "X-API-Key", location: "header"
end

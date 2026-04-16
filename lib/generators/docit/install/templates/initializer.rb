# frozen_string_literal: true

Docit.configure do |config|
  # The title shown in the API documentation UI
  config.title = "<%= Rails.application.class.module_parent_name rescue 'My API' %>"

  # API version
  config.version = "1.0.0"

  # Description shown on the introduction page
  config.description = "API documentation powered by Docit"

  # Documentation UI: :scalar (default) or :swagger
  # config.default_ui = :scalar

  # Authentication scheme (options: :bearer, :basic, :api_key)
  # config.auth :bearer

  # For API key auth:
  # config.auth :api_key, name: "X-API-Key", location: "header"
end

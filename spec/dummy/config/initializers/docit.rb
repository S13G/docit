# frozen_string_literal: true

Docit.configure do |config|
  config.title = "Dummy Test API"
  config.version = "1.0.0"
  config.description = "A test API for Docit gem integration tests"
  config.auth :bearer

  config.tag "Authentication", description: "User registration and login"
  config.tag "Users", description: "User management endpoints"

  config.server "http://localhost:3000", description: "Development"
  config.server "https://api.example.com", description: "Production"
end

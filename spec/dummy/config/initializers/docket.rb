# frozen_string_literal: true

Docket.configure do |config|
  config.title = "Dummy Test API"
  config.version = "1.0.0"
  config.description = "A test API for Docket gem integration tests"
  config.auth :bearer
end

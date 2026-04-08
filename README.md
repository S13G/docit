# Docit

[![Gem Version](https://badge.fury.io/rb/docit.svg)](https://rubygems.org/gems/docit)
[![CI](https://github.com/S13G/docket/actions/workflows/ci.yml/badge.svg)](https://github.com/S13G/docket/actions/workflows/ci.yml)
[![Ruby](https://img.shields.io/badge/ruby-%3E%3D%203.2-red.svg)](https://www.ruby-lang.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Decorator-style API documentation for Ruby on Rails. Write OpenAPI 3.0 docs as clean DSL macros directly on your controller actions: no separate doc files, no RSpec integration required. Just annotate and go.

Inspired by [drf-spectacular](https://github.com/tfranzel/drf-spectacular) for Django REST Framework.

## Installation

Add Docit to your Gemfile:

```ruby
gem "docit"
```

Then run:

```bash
bundle install
rails generate docit:install
```

The generator does two things:

1. Creates `config/initializers/docit.rb` with default settings
2. Mounts the Swagger UI engine at `/api-docs` in your routes

Visit `/api-docs` to see your interactive API documentation.

## Configuration

Edit `config/initializers/docit.rb`:

```ruby
Docit.configure do |config|
  config.title       = "My API"
  config.version     = "1.0.0"
  config.description = "Backend API documentation"

  # Authentication: pick one (or multiple):
  config.auth :bearer                              # Bearer token (JWT by default)
  config.auth :basic                               # HTTP Basic
  config.auth :api_key, name: "X-API-Key",         # API key in header
                         location: "header"

  # Tag descriptions (shown in Swagger UI sidebar):
  config.tag "Users", description: "User account management"
  config.tag "Auth",  description: "Authentication endpoints"

  # Server URLs (shown in Swagger UI server dropdown):
  config.server "https://api.example.com", description: "Production"
  config.server "https://staging.example.com", description: "Staging"
  config.server "http://localhost:3000", description: "Development"
end
```

## Usage

Docit supports two styles for documenting endpoints. Choose whichever fits your project or mix both.

### Style 1: Inline (simple APIs)

Add `swagger_doc` blocks directly in your controller:

```ruby
class Api::V1::UsersController < ApplicationController
  swagger_doc :index do
    summary "List all users"
    tags "Users"
    response 200, "Users retrieved"
  end
  def index
    # your code
  end
end
```

### Style 2: Separate doc files (recommended for larger APIs)

Keep controllers clean by defining docs in dedicated files, just like drf-spectacular:

```ruby
# app/docs/api/v1/users_docs.rb
module Api::V1::UsersDocs
  extend Docit::DocFile

  doc :index do
    summary "List all users"
    description "Returns a paginated list of users"
    tags "Users"

    parameter :page, location: :query, type: :integer, description: "Page number"

    response 200, "Users retrieved" do
      property :users, type: :array, items: :object do
        property :id, type: :integer, example: 1
        property :email, type: :string, example: "user@example.com"
      end
      property :total, type: :integer, example: 42
    end
  end

  doc :create do
    summary "Create a user"
    tags "Users"

    request_body required: true do
      property :email, type: :string, required: true
      property :password, type: :string, required: true, format: :password
    end

    response 201, "User created" do
      property :id, type: :integer
    end

    response 422, "Validation failed" do
      property :errors, type: :object do
        property :email, type: :array, items: :string
      end
    end
  end
end

# app/controllers/api/v1/users_controller.rb — stays clean!
class Api::V1::UsersController < ApplicationController
  use_docs Api::V1::UsersDocs

  def index
    # pure business logic
  end

  def create
    # pure business logic
  end
end
```

You can also mix both styles — use `use_docs` for most actions and add inline `swagger_doc` for one-offs:

```ruby
class Api::V1::UsersController < ApplicationController
  use_docs Api::V1::UsersDocs        # loads :index and :create from doc file

  swagger_doc :destroy do             # inline doc for this one action
    summary "Delete user"
    tags "Users"
    response 204, "Deleted"
  end

  def index; end
  def create; end
  def destroy; end
end
```

### Endpoint documentation DSL

The following examples work in both `swagger_doc` blocks and `doc` blocks.

### Request bodies

```ruby
swagger_doc :create do
  summary "Create a user"
  tags "Users"

  request_body required: true do
    property :email, type: :string, required: true, example: "user@example.com"
    property :password, type: :string, required: true, format: :password
    property :name, type: :string, example: "Jane Doe"
    property :profile, type: :object do
      property :bio, type: :string
      property :avatar_url, type: :string, format: :uri
    end
  end

  response 201, "User created" do
    property :id, type: :integer, example: 1
    property :email, type: :string, example: "user@example.com"
  end

  response 422, "Validation failed" do
    property :errors, type: :object do
      property :email, type: :array, items: :string
    end
  end
end
def create
  # your code
end
```

### Path parameters

```ruby
swagger_doc :show do
  summary "Get a user"
  tags "Users"

  parameter :id, location: :path, type: :integer, required: true, description: "User ID"

  response 200, "User found" do
    property :id, type: :integer, example: 1
    property :email, type: :string
    property :name, type: :string
  end

  response 404, "User not found" do
    property :error, type: :string, example: "Not found"
  end
end
def show
  # your code
end
```

### Enums

```ruby
swagger_doc :index do
  summary "List orders"
  tags "Orders"

  parameter :status, location: :query, type: :string,
            enum: %w[pending shipped delivered],
            description: "Filter by status"

  response 200, "Orders list" do
    property :orders, type: :array do
      property :id, type: :integer
      property :status, type: :string, enum: %w[pending shipped delivered]
    end
  end
end
```

### Security

Mark endpoints as requiring authentication:

```ruby
swagger_doc :destroy do
  summary "Delete a user"
  tags "Users"
  security :bearer_auth      # references the scheme from your config

  response 204, "User deleted"
  response 401, "Unauthorized"
end
```

### Deprecated endpoints

```ruby
swagger_doc :legacy_search do
  summary "Search (legacy)"
  tags "Search"
  deprecated

  response 200, "Results"
end
```

### Nested objects and arrays

```ruby
response 200, "Success" do
  property :user, type: :object do
    property :id, type: :integer
    property :name, type: :string
    property :addresses, type: :array do
      property :street, type: :string
      property :city, type: :string
      property :zip, type: :string
    end
  end
end
```

### Response examples

```ruby
response 200, "User found" do
  property :id, type: :integer
  property :email, type: :string

  example "admin_user",
          { id: 1, email: "admin@example.com" },
          description: "An admin user"

  example "regular_user",
          { id: 2, email: "user@example.com" },
          description: "A regular user"
end
```

### Shared schemas (`$ref`)

Define reusable schemas once and reference them across multiple endpoints:

```ruby
# In config/initializers/docit.rb or a dedicated file:
Docit.define_schema :User do
  property :id,    type: :integer, example: 1
  property :email, type: :string,  example: "user@example.com"
  property :name,  type: :string,  example: "Jane Doe"
  property :address, type: :object do
    property :street, type: :string
    property :city,   type: :string
  end
end

Docit.define_schema :Error do
  property :error,   type: :string, example: "Not found"
  property :details, type: :array, items: :string
end
```

Reference them in any endpoint with `schema ref:`:

```ruby
swagger_doc :show do
  summary "Get user"
  tags "Users"

  response 200, "User found" do
    schema ref: :User
  end

  response 404, "Not found" do
    schema ref: :Error
  end
end

swagger_doc :create do
  summary "Create user"
  tags "Users"

  request_body required: true do
    schema ref: :User
  end

  response 201, "Created" do
    schema ref: :User
  end
end
```

This outputs `$ref: '#/components/schemas/User'` in the spec — Swagger UI resolves it automatically.

### File uploads

Use `type: :file` with `content_type: "multipart/form-data"` for file upload endpoints:

```ruby
swagger_doc :upload_avatar do
  summary "Upload avatar"
  tags "Users"

  request_body required: true, content_type: "multipart/form-data" do
    property :avatar, type: :file, required: true, description: "Avatar image"
    property :caption, type: :string
  end

  response 201, "Avatar uploaded" do
    property :url, type: :string, format: :uri
  end
end
```

`type: :file` maps to `{ type: "string", format: "binary" }` in the OpenAPI spec.

## How it works

1. `swagger_doc` registers an **Operation** for each controller action in a global **Registry**
2. When someone visits `/api-docs/spec`, Docit's **SchemaGenerator** combines all registered operations with your Rails routes (via **RouteInspector**) to produce an OpenAPI 3.0.3 JSON document
3. The **Engine** serves Swagger UI at `/api-docs`, pointing it at the generated spec

The DSL is included in all controllers automatically via a Rails Engine initializer — no manual `include` needed if you're using `ActionController::API` or `ActionController::Base`.

## Mounting at a different path

In `config/routes.rb`:

```ruby
mount Docit::Engine => "/docs"        # now at /docs instead of /api-docs
```

## JSON spec only

If you just want the raw OpenAPI JSON (e.g., for code generation):

```
GET /api-docs/spec
```

## Development

```bash
git clone https://github.com/S13G/docket.git
cd docit
bundle install
bundle exec rspec        # run all tests
```

## Contributing

Bug reports and pull requests are welcome on [GitHub](https://github.com/S13G/docket).

## License

[MIT](LICENSE.txt)

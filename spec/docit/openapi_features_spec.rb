# frozen_string_literal: true

require "docit"

RSpec.describe "OpenAPI features" do
  before do
    Docit::Registry.clear!
    Docit.reset_configuration!
    Docit.reset_schemas!
  end

  describe "Schema $ref components" do
    before do
      allow(Docit::RouteInspector).to receive(:routes_for)
        .and_return([])

      allow(Docit::RouteInspector).to receive(:routes_for)
        .with("UsersController", "show")
        .and_return([{ path: "/users/{id}", method: "get" }])

      allow(Docit::RouteInspector).to receive(:routes_for)
        .with("UsersController", "create")
        .and_return([{ path: "/users", method: "post" }])
    end

    it "defines schemas on the Docit module" do
      Docit.define_schema :User do
        property :id, type: :integer, example: 1
        property :email, type: :string, example: "user@example.com"
      end

      expect(Docit.schemas[:User]).to be_a(Docit::SchemaDefinition)
      expect(Docit.schemas[:User].properties.length).to eq(2)
    end

    it "supports nested properties in schema definitions" do
      Docit.define_schema :UserProfile do
        property :id, type: :integer
        property :address, type: :object do
          property :street, type: :string
          property :city, type: :string
        end
      end

      addr_prop = Docit.schemas[:UserProfile].properties.find { |p| p[:name] == :address }
      expect(addr_prop[:children]).to be_an(Array)
      expect(addr_prop[:children].length).to eq(2)
    end

    it "outputs schemas under components/schemas" do
      Docit.define_schema :User do
        property :id, type: :integer
        property :email, type: :string
      end

      spec = Docit::SchemaGenerator.generate
      schemas = spec[:components][:schemas]

      expect(schemas).to have_key("User")
      expect(schemas["User"][:type]).to eq("object")
      expect(schemas["User"][:properties]).to have_key("id")
      expect(schemas["User"][:properties]).to have_key("email")
    end

    it "generates $ref in responses" do
      Docit.define_schema :User do
        property :id, type: :integer
        property :email, type: :string
      end

      controller = Class.new do
        include Docit::DSL
        def self.name = "UsersController"

        swagger_doc :show do
          summary "Get user"

          response 200, "User found" do
            schema ref: :User
          end
        end
      end

      spec = Docit::SchemaGenerator.generate
      response_schema = spec[:paths]["/users/{id}"]["get"][:responses]["200"][:content]["application/json"][:schema]

      expect(response_schema).to eq({ "$ref" => "#/components/schemas/User" })
    end

    it "generates $ref in request bodies" do
      Docit.define_schema :CreateUser do
        property :email, type: :string, required: true
        property :password, type: :string, required: true
      end

      controller = Class.new do
        include Docit::DSL
        def self.name = "UsersController"

        swagger_doc :create do
          summary "Create user"

          request_body required: true do
            schema ref: :CreateUser
          end

          response 201, "Created"
        end
      end

      spec = Docit::SchemaGenerator.generate
      body_schema = spec[:paths]["/users"]["post"][:requestBody][:content]["application/json"][:schema]

      expect(body_schema).to eq({ "$ref" => "#/components/schemas/CreateUser" })
    end

    it "does not include schemas key when no schemas defined" do
      spec = Docit::SchemaGenerator.generate
      expect(spec[:components]).not_to have_key(:schemas)
    end

    it "resets schemas with reset_schemas!" do
      Docit.define_schema(:Temp) { property :x, type: :string }
      expect(Docit.schemas).to have_key(:Temp)

      Docit.reset_schemas!
      expect(Docit.schemas).to be_empty
    end
  end

  describe "File upload / multipart" do
    before do
      allow(Docit::RouteInspector).to receive(:routes_for)
        .and_return([])

      allow(Docit::RouteInspector).to receive(:routes_for)
        .with("UploadsController", "create")
        .and_return([{ path: "/uploads", method: "post" }])
    end

    it "maps file type to string/binary in schema" do
      controller = Class.new do
        include Docit::DSL
        def self.name = "UploadsController"

        swagger_doc :create do
          summary "Upload file"

          request_body required: true, content_type: "multipart/form-data" do
            property :file, type: :file, required: true, description: "The file to upload"
            property :caption, type: :string
          end

          response 201, "Uploaded"
        end
      end

      spec = Docit::SchemaGenerator.generate
      body = spec[:paths]["/uploads"]["post"][:requestBody]
      schema = body[:content]["multipart/form-data"][:schema]

      expect(schema[:properties]["file"]).to eq({
                                                  type: "string",
                                                  format: "binary",
                                                  description: "The file to upload"
                                                })
      expect(schema[:properties]["caption"]).to eq({ type: "string" })
    end

    it "preserves required on the request body" do
      controller = Class.new do
        include Docit::DSL
        def self.name = "UploadsController"

        swagger_doc :create do
          request_body required: true, content_type: "multipart/form-data" do
            property :file, type: :file, required: true
          end

          response 201, "Uploaded"
        end
      end

      spec = Docit::SchemaGenerator.generate
      body = spec[:paths]["/uploads"]["post"][:requestBody]

      expect(body[:required]).to be true
      expect(body[:content]["multipart/form-data"][:schema][:required]).to eq(["file"])
    end
  end

  describe "Tag descriptions" do
    it "adds tags to configuration" do
      Docit.configure do |config|
        config.tag "Users", description: "User management"
        config.tag "Auth", description: "Authentication endpoints"
      end

      expect(Docit.configuration.tags).to eq([
                                               { name: "Users", description: "User management" },
                                               { name: "Auth", description: "Authentication endpoints" }
                                             ])
    end

    it "includes tags array in generated spec" do
      Docit.configure do |config|
        config.tag "Users", description: "User management"
      end

      spec = Docit::SchemaGenerator.generate

      expect(spec[:tags]).to eq([
                                  { name: "Users", description: "User management" }
                                ])
    end

    it "supports tags without descriptions" do
      Docit.configure do |config|
        config.tag "Misc"
      end

      spec = Docit::SchemaGenerator.generate

      expect(spec[:tags]).to eq([{ name: "Misc" }])
    end

    it "omits tags key when none configured" do
      spec = Docit::SchemaGenerator.generate
      expect(spec).not_to have_key(:tags)
    end

    it "returns a copy from tags accessor" do
      Docit.configure do |config|
        config.tag "Users"
      end

      tags1 = Docit.configuration.tags
      tags1 << { name: "Injected" }

      expect(Docit.configuration.tags.length).to eq(1)
    end
  end

  describe "Servers" do
    it "adds servers to configuration" do
      Docit.configure do |config|
        config.server "https://api.example.com", description: "Production"
        config.server "https://staging.example.com", description: "Staging"
      end

      expect(Docit.configuration.servers).to eq([
                                                  { url: "https://api.example.com", description: "Production" },
                                                  { url: "https://staging.example.com", description: "Staging" }
                                                ])
    end

    it "includes servers array in generated spec" do
      Docit.configure do |config|
        config.server "https://api.example.com", description: "Production"
      end

      spec = Docit::SchemaGenerator.generate

      expect(spec[:servers]).to eq([
                                     { url: "https://api.example.com", description: "Production" }
                                   ])
    end

    it "supports servers without descriptions" do
      Docit.configure do |config|
        config.server "http://localhost:3000"
      end

      spec = Docit::SchemaGenerator.generate
      expect(spec[:servers]).to eq([{ url: "http://localhost:3000" }])
    end

    it "omits servers key when none configured" do
      spec = Docit::SchemaGenerator.generate
      expect(spec).not_to have_key(:servers)
    end
  end
end

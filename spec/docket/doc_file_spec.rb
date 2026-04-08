# frozen_string_literal: true

require "docket"

RSpec.describe Docket::DocFile do
  before do
    Docket::Registry.clear!
    Docket.reset_configuration!
    Docket.reset_schemas!
  end

  describe "defining docs in a separate module" do
    let(:docs_module) do
      Module.new do
        extend Docket::DocFile

        doc :index do
          summary "List items"
          tags "Items"
          parameter :page, location: :query, type: :integer

          response 200, "Items retrieved" do
            property :items, type: :array, items: :object
            property :total, type: :integer
          end
        end

        doc :create do
          summary "Create item"
          tags "Items"

          request_body required: true do
            property :name, type: :string, required: true
            property :description, type: :string
          end

          response 201, "Item created" do
            property :id, type: :integer
          end

          response 422, "Validation failed" do
            property :errors, type: :object
          end
        end

        doc :show do
          summary "Get item"
          tags "Items"
          parameter :id, location: :path, type: :integer, required: true

          response 200, "Item found" do
            property :id, type: :integer
            property :name, type: :string
          end

          response 404, "Not found"
        end
      end
    end

    it "stores doc blocks by action name" do
      expect(docs_module.actions).to eq(%i[index create show])
    end

    it "retrieves a doc block by action name" do
      expect(docs_module[:index]).to be_a(Proc)
      expect(docs_module[:create]).to be_a(Proc)
    end

    it "returns nil for undefined actions" do
      expect(docs_module[:destroy]).to be_nil
    end
  end

  describe "use_docs in controller" do
    let(:docs_module) do
      Module.new do
        extend Docket::DocFile

        doc :index do
          summary "List users"
          tags "Users"

          response 200, "Users listed" do
            property :users, type: :array, items: :object
          end
        end

        doc :create do
          summary "Create user"
          tags "Users"

          request_body required: true do
            property :email, type: :string, required: true
            property :password, type: :string, required: true
          end

          response 201, "User created" do
            property :id, type: :integer
          end
        end
      end
    end

    it "registers all docs from the module onto the controller" do
      docs = docs_module
      Class.new do
        include Docket::DSL
        def self.name = "UsersController"

        use_docs docs
      end

      expect(Docket::Registry.operations.length).to eq(2)

      index_op = Docket::Registry.find(controller: "UsersController", action: "index")
      expect(index_op._summary).to eq("List users")
      expect(index_op._tags).to eq(["Users"])

      create_op = Docket::Registry.find(controller: "UsersController", action: "create")
      expect(create_op._summary).to eq("Create user")
      expect(create_op._request_body).not_to be_nil
    end

    it "can mix use_docs with inline swagger_doc" do
      docs = docs_module
      Class.new do
        include Docket::DSL
        def self.name = "UsersController"

        use_docs docs

        swagger_doc :destroy do
          summary "Delete user"
          tags "Users"
          response 204, "User deleted"
        end
      end

      expect(Docket::Registry.operations.length).to eq(3)
      destroy_op = Docket::Registry.find(controller: "UsersController", action: "destroy")
      expect(destroy_op._summary).to eq("Delete user")
    end
  end

  describe "full spec generation with DocFile" do
    before do
      allow(Docket::RouteInspector).to receive(:routes_for)
        .and_return([])

      allow(Docket::RouteInspector).to receive(:routes_for)
        .with("Api::V1::OrdersController", "index")
        .and_return([{ path: "/api/v1/orders", method: "get" }])

      allow(Docket::RouteInspector).to receive(:routes_for)
        .with("Api::V1::OrdersController", "create")
        .and_return([{ path: "/api/v1/orders", method: "post" }])
    end

    it "generates valid OpenAPI spec from doc files" do
      docs = Module.new do
        extend Docket::DocFile

        doc :index do
          summary "List orders"
          tags "Orders"

          parameter :status, location: :query, type: :string,
                    enum: %w[pending shipped delivered]

          response 200, "Orders retrieved" do
            property :orders, type: :array do
              property :id, type: :integer
              property :status, type: :string
            end
          end
        end

        doc :create do
          summary "Place order"
          tags "Orders"
          security :bearer_auth

          request_body required: true do
            property :product_id, type: :integer, required: true
            property :quantity, type: :integer, required: true
          end

          response 201, "Order placed" do
            property :order_id, type: :integer
          end
        end
      end

      Class.new do
        include Docket::DSL
        def self.name = "Api::V1::OrdersController"

        use_docs docs
      end

      Docket.configure do |config|
        config.title = "Orders API"
        config.version = "1.0.0"
        config.auth :bearer
      end

      spec = Docket::SchemaGenerator.generate

      # Verify paths exist
      expect(spec[:paths]).to have_key("/api/v1/orders")
      expect(spec[:paths]["/api/v1/orders"]).to have_key("get")
      expect(spec[:paths]["/api/v1/orders"]).to have_key("post")

      # Verify GET operation
      get_op = spec[:paths]["/api/v1/orders"]["get"]
      expect(get_op[:summary]).to eq("List orders")
      expect(get_op[:tags]).to eq(["Orders"])
      expect(get_op[:parameters].first[:name]).to eq("status")
      expect(get_op[:parameters].first[:schema][:enum]).to eq(%w[pending shipped delivered])

      # Verify POST operation
      post_op = spec[:paths]["/api/v1/orders"]["post"]
      expect(post_op[:summary]).to eq("Place order")
      expect(post_op[:security]).to eq([{ "bearer_auth" => [] }])
      expect(post_op[:requestBody][:required]).to be true
    end
  end
end

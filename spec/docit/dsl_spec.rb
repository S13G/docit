# frozen_string_literal: true

require "docit"

RSpec.describe Docit::DSL do
  before { Docit::Registry.clear! }

  let(:controller_class) do
    Class.new do
      include Docit::DSL

      def self.name
        "Api::V1::TestController"
      end

      swagger_doc :index do
        summary "List all items"
        tags "Items"
        response 200, "Success" do
          property :items, type: :array
        end
      end

      swagger_doc :create do
        summary "Create an item"
        tags "Items"
        request_body required: true do
          property :name, type: :string, required: true
        end
        response 201, "Created"
        response 422, "Validation error"
      end
    end
  end

  it "registers operations in the registry" do
    controller_class # trigger class evaluation
    expect(Docit::Registry.operations.length).to eq(2)
  end

  it "stores correct controller name" do
    controller_class
    op = Docit::Registry.find(controller: "Api::V1::TestController", action: "index")
    expect(op).not_to be_nil
    expect(op._summary).to eq("List all items")
  end

  it "stores request body details" do
    controller_class
    op = Docit::Registry.find(controller: "Api::V1::TestController", action: "create")
    expect(op._request_body).not_to be_nil
    expect(op._request_body.required).to be true
    expect(op._responses.length).to eq(2)
  end
end

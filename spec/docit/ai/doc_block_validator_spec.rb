# frozen_string_literal: true

require "docit"

RSpec.describe Docit::Ai::DocBlockValidator do
  let(:controller) { "Api::V1::OrdersController" }
  let(:action) { :show }

  describe "#validate!" do
    context "when the doc block uses the supported DSL" do
      let(:doc_block) do
        <<~RUBY
          doc :show do
            summary "Show an order"

            response 200, "Order found" do
              property :id, type: :integer, example: 1
              property :shipping_address, type: :object do
                property :city, type: :string, example: "Lagos"
              end
            end
          end
        RUBY
      end

      it "accepts the generated block" do
        validator = described_class.new(controller: controller, action: action, doc_block: doc_block)

        expect(validator.validate!).to be true
      end
    end

    context "when the generated block calls unsupported DSL methods" do
      let(:doc_block) do
        <<~RUBY
          doc :show do
            response 200, "Order found" do
              object do
                property :id, type: :integer, example: 1
              end
            end
          end
        RUBY
      end

      it "raises a validation error before the file is written" do
        validator = described_class.new(controller: controller, action: action, doc_block: doc_block)

        expect { validator.validate! }.to raise_error(Docit::Ai::InvalidDocBlockError, /object/)
      end
    end

    context "when the generated block defines the wrong action" do
      let(:doc_block) do
        <<~RUBY
          doc :index do
            response 200, "Orders found"
          end
        RUBY
      end

      it "raises a validation error" do
        validator = described_class.new(controller: controller, action: action, doc_block: doc_block)

        expect { validator.validate! }.to raise_error(Docit::Ai::InvalidDocBlockError, /doc :show/)
      end
    end
  end
end

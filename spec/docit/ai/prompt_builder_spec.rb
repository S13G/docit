# frozen_string_literal: true

require "docit"

RSpec.describe Docit::Ai::PromptBuilder do
  let(:gap) do
    {
      controller: "Api::V1::UsersController",
      action: "index",
      method: "get",
      path: "/api/v1/users"
    }
  end

  let(:builder) { described_class.new(gap: gap) }

  describe "#build" do
    let(:prompt) { builder.build }

    it "includes the DSL reference" do
      expect(prompt).to include("summary")
      expect(prompt).to include("request_body")
      expect(prompt).to include("response")
      expect(prompt).to include("parameter")
    end

    it "includes the example doc block" do
      expect(prompt).to include("doc :register do")
    end

    it "includes endpoint details" do
      expect(prompt).to include("Api::V1::UsersController")
      expect(prompt).to include("index")
      expect(prompt).to include("GET")
      expect(prompt).to include("/api/v1/users")
    end

    it "includes generation rules" do
      expect(prompt).to include("Output ONLY")
      expect(prompt).to include("No module wrapper")
      expect(prompt).to include("doc :index do")
      expect(prompt).to include("Use ONLY the DSL methods listed above")
      expect(prompt).to include("Never call standalone helpers such as `object`")
    end

    context "with path parameters" do
      let(:gap) do
        {
          controller: "Api::V1::UsersController",
          action: "show",
          method: "get",
          path: "/api/v1/users/{id}"
        }
      end

      it "includes path with parameter" do
        expect(prompt).to include("{id}")
        expect(prompt).to include("Infer parameters from the path")
      end
    end

    context "when regenerating after invalid output" do
      let(:prompt) { builder.build(validation_error: "NameError: undefined local variable or method `object'") }

      it "includes the validation feedback" do
        expect(prompt).to include("Previous attempt failed Docit validation")
        expect(prompt).to include("undefined local variable or method `object'")
        expect(prompt).to include("Regenerate the block and fix that error")
      end
    end
  end
end

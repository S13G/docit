# frozen_string_literal: true

require "docit"
require "tmpdir"

RSpec.describe Docit::Ai::DocWriter do
  let(:tmpdir) { Dir.mktmpdir }

  before do
    root = Pathname.new(tmpdir)
    rails = Module.new
    rails.define_singleton_method(:root) { root }
    stub_const("Rails", rails)
  end

  after { FileUtils.remove_entry(tmpdir) }

  let(:writer) { described_class.new(controller_name: "Api::V1::UsersController") }

  describe "#doc_file_path" do
    it "follows the convention: app/docs/<namespace>/<name>_docs.rb" do
      expected = File.join(tmpdir, "app", "docs", "api", "v1", "users_docs.rb")
      expect(writer.doc_file_path).to eq(expected)
    end
  end

  describe "#doc_module_name" do
    it "converts controller name to docs module name" do
      expect(writer.doc_module_name).to eq("Api::V1::UsersDocs")
    end
  end

  describe "#write (new file)" do
    let(:doc_block) do
      <<~RUBY
        doc :index do
          summary "List all users"
          tags "Users"
          response 200, "Success"
        end
      RUBY
    end

    it "creates the doc file with correct module structure" do
      writer.write([doc_block])

      content = File.read(writer.doc_file_path)
      expect(content).to include("# frozen_string_literal: true")
      expect(content).to include("module Api")
      expect(content).to include("  module V1")
      expect(content).to include("    module UsersDocs")
      expect(content).to include("      extend Docit::DocFile")
      expect(content).to include("doc :index do")
      expect(content).to include('summary "List all users"')
    end

    it "creates intermediate directories" do
      writer.write([doc_block])
      expect(File.directory?(File.dirname(writer.doc_file_path))).to be true
    end
  end

  describe "#write (append to existing)" do
    let(:existing_content) do
      <<~RUBY
        # frozen_string_literal: true

        module Api
          module V1
            module UsersDocs
              extend Docit::DocFile

              doc :index do
                summary "List all users"
                tags "Users"
                response 200, "Success"
              end
            end
          end
        end
      RUBY
    end

    let(:new_block) do
      <<~RUBY
        doc :show do
          summary "Get a user"
          tags "Users"
          response 200, "User found"
        end
      RUBY
    end

    it "appends new doc blocks to existing file" do
      FileUtils.mkdir_p(File.dirname(writer.doc_file_path))
      File.write(writer.doc_file_path, existing_content)

      writer.write([new_block])

      content = File.read(writer.doc_file_path)
      expect(content).to include("doc :index do")
      expect(content).to include("doc :show do")
      expect(content).to include('summary "Get a user"')
    end
  end

  describe "#controller_has_use_docs?" do
    it "returns false when controller file does not exist" do
      expect(writer.controller_has_use_docs?).to be false
    end

    it "returns true when controller has use_docs" do
      controller_path = File.join(tmpdir, "app", "controllers", "api", "v1", "users_controller.rb")
      FileUtils.mkdir_p(File.dirname(controller_path))
      File.write(controller_path, "class Api::V1::UsersController\n  use_docs Api::V1::UsersDocs\nend")

      expect(writer.controller_has_use_docs?).to be true
    end

    it "returns false when controller lacks use_docs" do
      controller_path = File.join(tmpdir, "app", "controllers", "api", "v1", "users_controller.rb")
      FileUtils.mkdir_p(File.dirname(controller_path))
      File.write(controller_path, "class Api::V1::UsersController\nend")

      expect(writer.controller_has_use_docs?).to be false
    end
  end

  describe "#inject_use_docs" do
    let(:controller_path) { File.join(tmpdir, "app", "controllers", "api", "v1", "users_controller.rb") }

    it "inserts use_docs after the class declaration" do
      FileUtils.mkdir_p(File.dirname(controller_path))
      File.write(controller_path, <<~RUBY)
        module Api
          module V1
            class UsersController < ApplicationController
              def index
              end
            end
          end
        end
      RUBY

      expect(writer.inject_use_docs).to be true

      content = File.read(controller_path)
      expect(content).to include("use_docs Api::V1::UsersDocs")
    end

    it "does not duplicate use_docs if already present" do
      FileUtils.mkdir_p(File.dirname(controller_path))
      File.write(controller_path, <<~RUBY)
        class Api::V1::UsersController < ApplicationController
          use_docs Api::V1::UsersDocs
        end
      RUBY

      expect(writer.inject_use_docs).to be false
    end

    it "returns false when controller file does not exist" do
      expect(writer.inject_use_docs).to be false
    end
  end
end

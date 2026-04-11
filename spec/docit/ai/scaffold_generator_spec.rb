# frozen_string_literal: true

require "docit"
require "tmpdir"
require "fileutils"

RSpec.describe Docit::Ai::ScaffoldGenerator do
  let(:tmpdir) { Dir.mktmpdir }
  let(:output) { StringIO.new }

  before do
    root = Pathname.new(tmpdir)
    rails = Module.new
    rails.define_singleton_method(:root) { root }
    stub_const("Rails", rails)

    FileUtils.mkdir_p(File.join(tmpdir, "config", "initializers"))
    File.write(File.join(tmpdir, "config", "initializers", "docit.rb"), <<~RUBY)
      Docit.configure do |config|
        config.title = "Test API"
      end
    RUBY
  end

  after { FileUtils.remove_entry(tmpdir) }

  describe "#run" do
    context "when Docit is not installed" do
      before { FileUtils.rm_f(File.join(tmpdir, "config", "initializers", "docit.rb")) }

      it "raises an error about missing install" do
        scaffold = described_class.new(output: output)
        expect { scaffold.run }.to raise_error(Docit::Error, /not installed.*rails generate docit:install/i)
      end
    end

    it "reports when no undocumented endpoints found" do
      allow_any_instance_of(Docit::Ai::GapDetector).to receive(:detect).and_return([])
      allow(Docit::RouteInspector).to receive(:eager_load_controllers!)

      scaffold = described_class.new(output: output)
      files = scaffold.run

      expect(output.string).to include("No undocumented endpoints found")
      expect(files).to be_empty
    end

    it "creates placeholder doc files for undocumented endpoints" do
      gaps = [
        { controller: "Api::V1::UsersController", action: "index", path: "/api/v1/users", method: "get" },
        { controller: "Api::V1::UsersController", action: "create", path: "/api/v1/users", method: "post" }
      ]
      allow_any_instance_of(Docit::Ai::GapDetector).to receive(:detect).and_return(gaps)
      allow(Docit::RouteInspector).to receive(:eager_load_controllers!)

      controller_dir = File.join(tmpdir, "app", "controllers", "api", "v1")
      FileUtils.mkdir_p(controller_dir)
      File.write(File.join(controller_dir, "users_controller.rb"), <<~RUBY)
        class Api::V1::UsersController < ApplicationController
          def index; end
          def create; end
        end
      RUBY

      scaffold = described_class.new(output: output)
      files = scaffold.run

      expect(files.length).to eq(1)
      doc_content = File.read(files.first)
      expect(doc_content).to include("module UsersDocs")
      expect(doc_content).to include("doc :index do")
      expect(doc_content).to include("doc :create do")
      expect(doc_content).to include("TODO")
    end

    it "generates placeholder with path parameters" do
      gaps = [
        { controller: "Api::V1::UsersController", action: "show", path: "/api/v1/users/{id}", method: "get" }
      ]
      allow_any_instance_of(Docit::Ai::GapDetector).to receive(:detect).and_return(gaps)
      allow(Docit::RouteInspector).to receive(:eager_load_controllers!)

      controller_dir = File.join(tmpdir, "app", "controllers", "api", "v1")
      FileUtils.mkdir_p(controller_dir)
      File.write(File.join(controller_dir, "users_controller.rb"), <<~RUBY)
        class Api::V1::UsersController < ApplicationController
          def show; end
        end
      RUBY

      scaffold = described_class.new(output: output)
      files = scaffold.run

      doc_content = File.read(files.first)
      expect(doc_content).to include("parameter :id, location: :path")
    end

    it "generates request_body placeholder for POST/PUT/PATCH" do
      gaps = [
        { controller: "Api::V1::UsersController", action: "create", path: "/api/v1/users", method: "post" }
      ]
      allow_any_instance_of(Docit::Ai::GapDetector).to receive(:detect).and_return(gaps)
      allow(Docit::RouteInspector).to receive(:eager_load_controllers!)

      controller_dir = File.join(tmpdir, "app", "controllers", "api", "v1")
      FileUtils.mkdir_p(controller_dir)
      File.write(File.join(controller_dir, "users_controller.rb"), <<~RUBY)
        class Api::V1::UsersController < ApplicationController
          def create; end
        end
      RUBY

      scaffold = described_class.new(output: output)
      files = scaffold.run

      doc_content = File.read(files.first)
      expect(doc_content).to include("request_body required: true")
      expect(doc_content).to include("response 201")
    end

    it "injects use_docs into controllers" do
      gaps = [
        { controller: "Api::V1::UsersController", action: "index", path: "/api/v1/users", method: "get" }
      ]
      allow_any_instance_of(Docit::Ai::GapDetector).to receive(:detect).and_return(gaps)
      allow(Docit::RouteInspector).to receive(:eager_load_controllers!)

      controller_dir = File.join(tmpdir, "app", "controllers", "api", "v1")
      FileUtils.mkdir_p(controller_dir)
      File.write(File.join(controller_dir, "users_controller.rb"), <<~RUBY)
        class Api::V1::UsersController < ApplicationController
          def index; end
        end
      RUBY

      scaffold = described_class.new(output: output)
      scaffold.run

      controller_content = File.read(File.join(controller_dir, "users_controller.rb"))
      expect(controller_content).to include("use_docs")
      expect(output.string).to include("Added use_docs")
    end

    it "uses DELETE 204 status for destroy actions" do
      gaps = [
        { controller: "Api::V1::UsersController", action: "destroy", path: "/api/v1/users/{id}", method: "delete" }
      ]
      allow_any_instance_of(Docit::Ai::GapDetector).to receive(:detect).and_return(gaps)
      allow(Docit::RouteInspector).to receive(:eager_load_controllers!)

      controller_dir = File.join(tmpdir, "app", "controllers", "api", "v1")
      FileUtils.mkdir_p(controller_dir)
      File.write(File.join(controller_dir, "users_controller.rb"), <<~RUBY)
        class Api::V1::UsersController < ApplicationController
          def destroy; end
        end
      RUBY

      scaffold = described_class.new(output: output)
      files = scaffold.run

      doc_content = File.read(files.first)
      expect(doc_content).to include("response 204")
    end

    it "uses 200 for update actions" do
      gaps = [
        { controller: "Api::V1::UsersController", action: "update", path: "/api/v1/users/{id}", method: "patch" }
      ]
      allow_any_instance_of(Docit::Ai::GapDetector).to receive(:detect).and_return(gaps)
      allow(Docit::RouteInspector).to receive(:eager_load_controllers!)

      controller_dir = File.join(tmpdir, "app", "controllers", "api", "v1")
      FileUtils.mkdir_p(controller_dir)
      File.write(File.join(controller_dir, "users_controller.rb"), <<~RUBY)
        class Api::V1::UsersController < ApplicationController
          def update; end
        end
      RUBY

      scaffold = described_class.new(output: output)
      files = scaffold.run

      doc_content = File.read(files.first)
      expect(doc_content).to include("response 200")
    end

    it "injects tags into initializer" do
      gaps = [
        { controller: "Api::V1::UsersController", action: "index", path: "/api/v1/users", method: "get" }
      ]
      allow_any_instance_of(Docit::Ai::GapDetector).to receive(:detect).and_return(gaps)
      allow(Docit::RouteInspector).to receive(:eager_load_controllers!)

      controller_dir = File.join(tmpdir, "app", "controllers", "api", "v1")
      FileUtils.mkdir_p(controller_dir)
      File.write(File.join(controller_dir, "users_controller.rb"), <<~RUBY)
        class Api::V1::UsersController < ApplicationController
          def index; end
        end
      RUBY

      scaffold = described_class.new(output: output)
      scaffold.run

      initializer = File.read(File.join(tmpdir, "config", "initializers", "docit.rb"))
      expect(initializer).to include('config.tag "Users"')
    end
  end
end

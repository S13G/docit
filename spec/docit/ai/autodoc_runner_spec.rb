# frozen_string_literal: true

require "docit"
require "tmpdir"
require "fileutils"

RSpec.describe Docit::Ai::AutodocRunner do
  let(:tmpdir) { Dir.mktmpdir }
  let(:input) { StringIO.new }
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
        runner = described_class.new(output: output)
        expect { runner.run }.to raise_error(Docit::Error, /not installed.*rails generate docit:install/i)
      end
    end

    context "when engine route is missing" do
      before do
        Docit::Ai::Configuration.save(provider: "openai", model: "gpt-4o-mini", api_key: "sk-test")
        File.write(File.join(tmpdir, "config", "routes.rb"), "Rails.application.routes.draw do\nend\n")
      end

      it "warns about missing engine mount" do
        allow_any_instance_of(Docit::Ai::GapDetector).to receive(:detect).and_return([])

        runner = described_class.new(input: input, output: output)
        runner.run

        expect(output.string).to include("Warning: Docit engine is not mounted")
      end
    end

    context "when AI is not configured" do
      it "raises an error" do
        runner = described_class.new(input: input, output: output)
        expect { runner.run }.to raise_error(Docit::Error, /AI not configured/)
      end
    end

    context "when AI is configured" do
      before do
        Docit::Ai::Configuration.save(provider: "openai", model: "gpt-4o-mini", api_key: "sk-test")
      end

      it "reports when all endpoints are documented" do
        allow_any_instance_of(Docit::Ai::GapDetector).to receive(:detect).and_return([])

        runner = described_class.new(input: input, output: output)
        results = runner.run

        expect(output.string).to include("All endpoints are documented!")
        expect(results[:gaps]).to be_empty
      end

      it "supports dry-run mode" do
        gaps = [{ controller: "Api::V1::UsersController", action: "index", path: "/api/v1/users", method: "get" }]
        allow_any_instance_of(Docit::Ai::GapDetector).to receive(:detect).and_return(gaps)

        runner = described_class.new(dry_run: true, input: input, output: output)
        results = runner.run

        expect(output.string).to include("[dry-run] No files written.")
        expect(results[:gaps].length).to eq(1)
      end

      it "generates docs and writes files" do
        gaps = [{ controller: "Api::V1::UsersController", action: "index", path: "/api/v1/users", method: "get" }]
        allow_any_instance_of(Docit::Ai::GapDetector).to receive(:detect).and_return(gaps)

        controller_dir = File.join(tmpdir, "app", "controllers", "api", "v1")
        FileUtils.mkdir_p(controller_dir)
        File.write(File.join(controller_dir, "users_controller.rb"), <<~RUBY)
          class Api::V1::UsersController < ApplicationController
            def index; end
          end
        RUBY

        fake_client = double("client")
        allow(fake_client).to receive(:generate).and_return(<<~DOC)
          doc :index do
            summary "List users"
            tags "Users"
            response 200, "Success"
          end
        DOC
        allow(Docit::Ai::Client).to receive(:for).and_return(fake_client)

        runner = described_class.new(input: input, output: output)
        results = runner.run

        expect(results[:generated]).to eq(1)
        expect(results[:files].length).to eq(1)
        expect(File.exist?(results[:files].first)).to be true
        expect(output.string).to include("Docit will send controller source code")
        expect(output.string).to include("[1/1] Generating")
        expect(output.string).to include("done")
      end

      it "skips endpoints when controller source is missing" do
        gaps = [{ controller: "Api::V1::MissingController", action: "index", path: "/api/v1/missing", method: "get" }]
        allow_any_instance_of(Docit::Ai::GapDetector).to receive(:detect).and_return(gaps)

        fake_client = double("client")
        allow(fake_client).to receive(:generate)
        allow(Docit::Ai::Client).to receive(:for).and_return(fake_client)

        runner = described_class.new(input: input, output: output)
        results = runner.run

        expect(fake_client).not_to have_received(:generate)
        expect(output.string).to include("skipped (controller source file not found)")
        expect(results[:generated]).to eq(0)
      end

      it "handles AI errors gracefully" do
        gaps = [{ controller: "Api::V1::UsersController", action: "index", path: "/api/v1/users", method: "get" }]
        allow_any_instance_of(Docit::Ai::GapDetector).to receive(:detect).and_return(gaps)

        controller_dir = File.join(tmpdir, "app", "controllers", "api", "v1")
        FileUtils.mkdir_p(controller_dir)
        File.write(File.join(controller_dir, "users_controller.rb"), <<~RUBY)
          class Api::V1::UsersController < ApplicationController
            def index; end
          end
        RUBY

        fake_client = double("client")
        allow(fake_client).to receive(:generate).and_raise(Docit::Ai::Error, "rate limited")
        allow(Docit::Ai::Client).to receive(:for).and_return(fake_client)

        runner = described_class.new(input: input, output: output)
        results = runner.run

        expect(output.string).to include("failed (rate limited)")
        expect(results[:generated]).to eq(0)
      end
    end
  end
end

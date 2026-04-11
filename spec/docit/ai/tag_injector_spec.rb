# frozen_string_literal: true

require "docit"
require "tmpdir"

RSpec.describe Docit::Ai::TagInjector do
  let(:tmpdir) { Dir.mktmpdir }

  before do
    root = Pathname.new(tmpdir)
    rails = Module.new
    rails.define_singleton_method(:root) { root }
    stub_const("Rails", rails)
  end

  after { FileUtils.remove_entry(tmpdir) }

  let(:initializer_path) { File.join(tmpdir, "config", "initializers", "docit.rb") }

  let(:initializer_content) do
    <<~RUBY
      Docit.configure do |config|
        config.title = "My API"
        config.version = "1.0.0"
        config.auth :bearer

        config.tag "Authentication", description: "User registration and login"
        config.tag "Users", description: "User management endpoints"

        config.server "http://localhost:3000", description: "Development"
      end
    RUBY
  end

  before do
    FileUtils.mkdir_p(File.dirname(initializer_path))
    File.write(initializer_path, initializer_content)
  end

  describe "#inject" do
    it "adds new tags to the initializer" do
      injector = described_class.new(tags: %w[Products Orders])
      result = injector.inject

      expect(result).to match_array(%w[Products Orders])

      content = File.read(initializer_path)
      expect(content).to include('config.tag "Products", description: "Products management endpoints"')
      expect(content).to include('config.tag "Orders", description: "Orders management endpoints"')
    end

    it "skips tags that already exist" do
      injector = described_class.new(tags: %w[Authentication Products])
      result = injector.inject

      expect(result).to eq(["Products"])

      content = File.read(initializer_path)
      expect(content.scan(/config\.tag "Authentication"/).length).to eq(1)
    end

    it "returns empty when all tags exist" do
      injector = described_class.new(tags: %w[Authentication Users])
      result = injector.inject

      expect(result).to be_empty
    end

    it "returns empty when initializer does not exist" do
      File.delete(initializer_path)
      injector = described_class.new(tags: ["Products"])

      expect(injector.inject).to be_empty
    end
  end
end

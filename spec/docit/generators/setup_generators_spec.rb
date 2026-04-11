# frozen_string_literal: true

require "tmpdir"
require "fileutils"
require "rails/generators"
require_relative "../../../lib/generators/docit/install/install_generator"
require_relative "../../../lib/generators/docit/ai_setup/ai_setup_generator"

RSpec.describe Docit::Generators::InstallGenerator do
  let(:tmpdir) { Dir.mktmpdir }
  let(:generator) { described_class.new([], {}, destination_root: tmpdir) }

  before do
    root = Pathname.new(tmpdir)
    rails = Module.new
    rails.define_singleton_method(:root) { root }
    stub_const("Rails", rails)
    allow(generator).to receive(:say)
  end

  after { FileUtils.remove_entry(tmpdir) }

  it "retries invalid doc mode input" do
    allow(generator).to receive(:ask).and_return("banana", "2")

    generator.ask_doc_mode

    expect(generator.instance_variable_get(:@doc_mode)).to eq("2")
  end

  it "retries blank API keys" do
    allow(generator).to receive(:ask_secret).and_return("", "sk-test")

    expect(generator.send(:prompt_api_key, "openai")).to eq("sk-test")
  end

  it "warns when .gitignore is missing" do
    expect(generator).to receive(:say).with(/\.gitignore not found/, :yellow)

    generator.send(:update_gitignore)
  end
end

RSpec.describe Docit::Generators::AiSetupGenerator do
  let(:tmpdir) { Dir.mktmpdir }
  let(:generator) { described_class.new([], {}, destination_root: tmpdir) }

  before do
    root = Pathname.new(tmpdir)
    rails = Module.new
    rails.define_singleton_method(:root) { root }
    stub_const("Rails", rails)
    allow(generator).to receive(:say)
  end

  after { FileUtils.remove_entry(tmpdir) }

  it "retries invalid provider input" do
    allow(generator).to receive(:ask).and_return("0", "1")

    generator.prompt_provider

    expect(generator.instance_variable_get(:@provider)).to eq("openai")
  end

  it "retries blank API keys" do
    generator.instance_variable_set(:@provider, "openai")
    allow(generator).to receive(:ask_secret).and_return("", "sk-test")

    generator.prompt_api_key

    expect(generator.instance_variable_get(:@api_key)).to eq("sk-test")
  end

  it "warns when .gitignore is missing" do
    expect(generator).to receive(:say).with(/\.gitignore not found/, :yellow)

    generator.update_gitignore
  end
end

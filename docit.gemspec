# frozen_string_literal: true

require_relative "lib/docit/version"

Gem::Specification.new do |spec|
  spec.name = "docit"
  spec.version = Docit::VERSION
  spec.authors = ["S13G"]
  spec.email = ["siegdomain1@gmail.com"]

  spec.summary = "Decorator-style OpenAPI documentation for Rails with inline DSL, doc modules, and AI-assisted scaffolding."
  spec.description = "Write OpenAPI 3.0.3 documentation for Rails APIs with clean controller DSL macros, separate doc modules, and optional AI-assisted doc generation for undocumented endpoints."
  spec.homepage = "https://docitruby.dev"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/S13G/docit"
  spec.metadata["changelog_uri"] = "https://github.com/S13G/docit/blob/master/CHANGELOG.md"
  spec.metadata["documentation_uri"] = "https://docitruby.dev/docs"
  spec.metadata["bug_tracker_uri"] = "https://github.com/S13G/docit/issues"
  spec.metadata["rubygems_mfa_required"] = "true"

  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.end_with?(".docit_ai.yml") ||
        f.start_with?(*%w[bin/ Gemfile .gitignore .rspec spec/ .rubocop.yml])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "rails", ">= 7.0"
end

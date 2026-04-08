# frozen_string_literal: true

require_relative "lib/docket/version"

Gem::Specification.new do |spec|
  spec.name = "docket"
  spec.version = Docket::VERSION
  spec.authors = ["S13G"]
  spec.email = ["ayflix0@gmail.com"]

  spec.summary = "Decorator-style Swagger/OpenAPI documentation generator for Ruby on Rails."
  spec.description = "Docket lets you write OpenAPI 3.0 docs as clean DSL macros directly on your Rails controller actions. No RSpec integration required, no external doc files. Just annotate and go."
  spec.homepage = "https://github.com/S13G/docket"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/S13G/docket"
  spec.metadata["changelog_uri"] = "https://github.com/S13G/docket/blob/main/CHANGELOG.md"

  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore .rspec spec/ .rubocop.yml])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "rails", ">= 7.0"
end

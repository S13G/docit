# Contributing to Docit

Docit welcomes any form of contribution. Your contribution matters even if it is only a small one.

Contributions come in different shapes and sizes:

- Documentation improvements, clarifications & fixing typos
- Creating issues for feature requests & bug reports
- Creating pull requests for features and bug fixes
- Questions that highlight inconsistencies or workflow issues
- Adding support for additional authentication schemes or OpenAPI features

## Issues

Generating OpenAPI schemas from Rails controllers is subtle work — the devil often lies in the details. A concise description with examples goes a long way. If possible, please include:

- A concise description of the problem
- Example controller code that produces the issue
- The generated (partial) OpenAPI spec showing the problem
- Stacktraces if an error occurred
- Docit / Ruby / Rails versions (`bundle show docit`, `ruby -v`, `rails -v`)

## Pull requests

Docit aims for high test coverage and an extensive test suite. Tests enable us to maintain quality, reliability, and consistency as the gem grows.

- **Keep changes minimal.** Make the smallest invasive change that solves the problem. On receiving feedback, amend existing commits rather than adding fixup commits — use `git commit --amend` and `git push --force` to update your PR.
- **Get early feedback on non-trivial PRs.** Open an issue first to discuss the approach. We don't want to waste anyone's time.
- **Write tests.** Look at `spec/docit/` for unit test patterns and `spec/integration/` for engine tests. Small additions can go into `spec/docit/v2_features_spec.rb` or a new spec file for the feature.
- **All tests must pass.** Your PR must pass the full suite to be merged.

## Getting started

```bash
# Fork the repo on GitHub, then:
git clone https://github.com/S13G/docit.git
cd docit

# Install dependencies
bundle install

# Run the test suite
bundle exec rspec

# Run a specific test file
bundle exec rspec spec/docit/schema_generator_spec.rb

# Run a single test by line number
bundle exec rspec spec/docit/v2_features_spec.rb:30
```

## Project structure

```
lib/docit.rb                          # Entry point, configuration, schema registry
lib/docit/configuration.rb            # Config class (title, auth, tags)
lib/docit/registry.rb                 # Global operation store
lib/docit/dsl.rb                      # swagger_doc macro
lib/docit/operation.rb                # Single endpoint documentation
lib/docit/builders/                   # DSL builders (response, request_body, parameter)
lib/docit/schema_definition.rb        # Reusable $ref schema definitions
lib/docit/schema_generator.rb         # Registry → OpenAPI 3.0.3 spec
lib/docit/route_inspector.rb          # Rails route introspection
lib/docit/engine.rb                   # Rails Engine (Swagger UI + spec endpoint)
app/controllers/docit/ui_controller.rb # Serves Swagger UI and JSON spec
lib/generators/docit/install/         # rails g docit:install generator
spec/dummy/                            # Minimal Rails app for integration tests
```

## Code style

- Follow existing patterns in the codebase
- Use `frozen_string_literal: true` in all Ruby files
- Prefer keyword arguments for clarity (`location:` instead of positional args)
- Use `instance_eval(&block)` for DSL blocks
- Return defensive copies (`.dup`) from accessor methods that expose internal state

With that out of the way, we hope to hear from you soon.

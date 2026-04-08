# Contributing to Docket

Docket welcomes any form of contribution. Your contribution matters even if it is only a small one.

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
- Docket / Ruby / Rails versions (`bundle show docket`, `ruby -v`, `rails -v`)

## Pull requests

Docket aims for high test coverage and an extensive test suite. Tests enable us to maintain quality, reliability, and consistency as the gem grows.

- **Keep changes minimal.** Make the smallest invasive change that solves the problem. On receiving feedback, amend existing commits rather than adding fixup commits — use `git commit --amend` and `git push --force` to update your PR.
- **Get early feedback on non-trivial PRs.** Open an issue first to discuss the approach. We don't want to waste anyone's time.
- **Write tests.** Look at `spec/docket/` for unit test patterns and `spec/integration/` for engine tests. Small additions can go into `spec/docket/v2_features_spec.rb` or a new spec file for the feature.
- **All tests must pass.** Your PR must pass the full suite to be merged.

## Getting started

```bash
# Fork the repo on GitHub, then:
git clone https://github.com/YOURGITHUBNAME/docket.git
cd docket

# Install dependencies
bundle install

# Run the test suite
bundle exec rspec

# Run a specific test file
bundle exec rspec spec/docket/schema_generator_spec.rb

# Run a single test by line number
bundle exec rspec spec/docket/v2_features_spec.rb:30
```

## Project structure

```
lib/docket.rb                          # Entry point, configuration, schema registry
lib/docket/configuration.rb            # Config class (title, auth, tags)
lib/docket/registry.rb                 # Global operation store
lib/docket/dsl.rb                      # swagger_doc macro
lib/docket/operation.rb                # Single endpoint documentation
lib/docket/builders/                   # DSL builders (response, request_body, parameter)
lib/docket/schema_definition.rb        # Reusable $ref schema definitions
lib/docket/schema_generator.rb         # Registry → OpenAPI 3.0.3 spec
lib/docket/route_inspector.rb          # Rails route introspection
lib/docket/engine.rb                   # Rails Engine (Swagger UI + spec endpoint)
app/controllers/docket/ui_controller.rb # Serves Swagger UI and JSON spec
lib/generators/docket/install/         # rails g docket:install generator
spec/dummy/                            # Minimal Rails app for integration tests
```

## Code style

- Follow existing patterns in the codebase
- Use `frozen_string_literal: true` in all Ruby files
- Prefer keyword arguments for clarity (`location:` instead of positional args)
- Use `instance_eval(&block)` for DSL blocks
- Return defensive copies (`.dup`) from accessor methods that expose internal state

With that out of the way, we hope to hear from you soon.

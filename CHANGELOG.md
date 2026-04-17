## [Unreleased]

## [0.3.1] - 2026-04-17

### Fixed
- Fixed gem packaging: `doc_block_validator.rb` was missing from the published 0.3.0 gem, causing `LoadError` on require

## [0.3.0] - 2026-04-16

### Added
- Scalar API Reference as a second documentation UI alongside Swagger UI
- New routes: `/api-docs/scalar` and `/api-docs/swagger` for direct access to each UI
- `config.default_ui` option (`:scalar` or `:swagger`) to control which UI renders at the root `/api-docs` path
- Navigation bar across both UIs for one-click switching between Scalar and Swagger
- Modular renderer architecture (`Docit::UI::BaseRenderer`, `SwaggerRenderer`, `ScalarRenderer`) for easy extension

### Changed
- Default documentation UI is now Scalar (previously Swagger UI)
- `config.description` now defaults to a welcome message instead of an empty string
- Install generator template now documents the `default_ui` option
- UI controller refactored from monolithic HTML generation to thin dispatcher with pluggable renderers

## [0.2.1] - 2026-04-11

### Fixed
- Engine autoloading: `Docit::Engine` is now properly required when Rails is present, fixing `uninitialized constant Docit::Engine` and `Could not find generator 'docit:install'` in consuming apps
- AI provider clients (OpenAI, Anthropic, Groq) now raise `Docit::Ai::RateLimitError` on 429 responses with parsed retry-after timing
- `AutodocRunner` now retries rate-limited requests up to 3 times with exponential backoff (capped at 5 minutes) instead of failing immediately

## [0.2.0] - 2026-04-11

### Added
- Unified install generator: `rails g docit:install` now offers AI auto-docs, manual scaffolding, or skip
- Manual scaffold mode: creates doc file placeholders with TODO markers, injects `use_docs` into controllers
- `AutodocRunner` class: reusable orchestrator for AI doc generation (used by both install generator and rake task)
- `ScaffoldGenerator` class: creates placeholder doc files for manual documentation
- Groq provider support (free tier) alongside OpenAI and Anthropic
- AI configuration generator: `rails g docit:ai_setup`
- Tasks: `rails docit:autodoc` with preview support via `DRY_RUN=1`
- Auto-injection of `use_docs` into controllers after doc generation
- Auto-injection of `config.tag` entries into initializer

### Changed
- AI setup flows now retry invalid menu input instead of exiting immediately
- AI setup flows now hide API key input in interactive terminals
- `rails docit:autodoc` now supports `DRY_RUN=1` for preview mode
- AI autodoc now warns before sending controller source to external providers
- Swagger UI assets are pinned to a specific `swagger-ui-dist` version

### Fixed
- `.docit_ai.yml` is now written with restricted file permissions
- AI provider clients now return a clean Docit error when an upstream service responds with invalid JSON
- Swagger UI now escapes the generated spec URL before embedding it in JavaScript
- Manual scaffolds now use `200` for `PUT` and `PATCH` responses by default

## [0.1.0] - 2026-04-08

- Initial release
- DSL: `swagger_doc` macro for inline controller documentation
- DSL: `use_docs` + `Docit::DocFile` for separate doc files
- Builders: request body, response, and parameter builders with nested object/array support
- Schema `$ref` components via `Docit.define_schema`
- File upload support (`type: :file` → `string/binary`)
- Configuration: auth schemes (bearer, basic, api_key), tag descriptions, server URLs
- Rails Engine: Swagger UI at mounted path, JSON spec endpoint
- Route introspection with eager-loading for development mode
- Install generator: `rails g docit:install`
- OpenAPI 3.0.3 spec generation

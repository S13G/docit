## [Unreleased]

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

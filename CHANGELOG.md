## [Unreleased]

## [0.1.0] - 2026-04-08

- Initial release
- DSL: `swagger_doc` macro for inline controller documentation
- DSL: `use_docs` + `Docket::DocFile` for separate doc files (drf-spectacular style)
- Builders: request body, response, and parameter builders with nested object/array support
- Schema `$ref` components via `Docket.define_schema`
- File upload support (`type: :file` → `string/binary`)
- Configuration: auth schemes (bearer, basic, api_key), tag descriptions, server URLs
- Rails Engine: Swagger UI at mounted path, JSON spec endpoint
- Route introspection with eager-loading for development mode
- Install generator: `rails g docket:install`
- OpenAPI 3.0.3 spec generation

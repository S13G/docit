# Troubleshooting

Common questions and fixes when working with Docit.

## My route isn't showing up in the spec

Docit only documents an endpoint if **both** are true:

1. The route exists in `config/routes.rb` (visible in `rails routes`).
2. A doc is registered for that controller + action — either inline with `doc_for :action do ... end` or via `use_docs SomeDocs`.

A route with no matching `doc_for`/`use_docs` is simply absent from `/api-docs/spec`. It will still appear on the **System Map** (`/api-docs/system`) marked `undocumented`, which is the quickest way to see your coverage gaps.

Checklist:

- Is the action name spelled exactly the same in the route and in `doc_for`?
- Is the controller actually loaded? Docit eager-loads controllers when generating the spec, but a controller in a non-standard path may be missed.
- If using `use_docs`, does the doc module define a `doc :action` block for that action?

## A doc_for option seems to be ignored

Docit's DSL methods are explicit. If you mistype one (e.g. `summmary` instead of `summary`), the call currently does nothing rather than raising — so the option silently disappears.

Double-check the spelling of DSL methods against the [DSL reference in the README](README.md). The supported response/property options include `summary`, `description`, `tags`, `response`, `request_body`, `parameter`, `property` (with `type`, `format`, `example`, `enum`, `default`, `nullable`, `read_only`, `write_only`), `header`, `schema ref:`, `security`, `deprecated`, and `operation_id`.

## A System Map section says "undocumented" or shows low coverage

That section's endpoints have no registered docs. Add `doc_for`/`use_docs` for those actions, or accept the gap — coverage is informational, not an error.

## Schemas aren't linked on the System Map

`uses_schema` edges only appear when a documented endpoint references a shared schema with `schema ref: :Name` (in its request body or a response), and that schema is defined with `Docit.define_schema :Name`. A plain inline `property` block does not create a schema node.

## I documented an action twice and my changes are ignored

Docit's registry keeps the **first** doc registered for a given controller + action and ignores later ones. So if an action is already documented (e.g. via `use_docs SomeDocs`) and you also add an inline `doc_for :same_action do ... end`, the inline block is silently dropped — the `use_docs` version wins.

Document each action in exactly one place. If you need to override a shared doc module for one action, change it in the module rather than re-declaring it on the controller.

## AI autodoc / scaffolding isn't working

- Run `rails generate docit:ai_setup` once to configure a provider (OpenAI, Anthropic, or Groq). The key is written to `.docit_ai.yml`, which the generator adds to `.gitignore` — **never commit it.**
- `rails docit:autodoc` sends controller **source code** to your configured provider. In an interactive terminal it asks for confirmation first; in a non-interactive context (CI, piping) it proceeds without prompting, so only run it where sending source is acceptable.
- Preview without writing files: `DRY_RUN=1 rails docit:autodoc`.
- Rate-limit / 429 errors are retried with backoff automatically; a persistent failure usually means an invalid key or an unsupported model name.

## The System Map or docs pages are exposed in production

The Docit endpoints are **unauthenticated by default**. They expose your API surface, the OpenAPI spec, and your app structure. In production, gate the engine — see [Restricting access in production](README.md#restricting-access-in-production) in the README. To disable the System Map specifically, set `config.system_graph_enabled = false`.

## Spec generation is slow on a large app

Generating the spec eager-loads controllers and walks every route. For very large apps this is a one-time cost per request; put the docs behind a cache or a non-production-only mount if it matters. The System Map graph is rebuilt per request — if that becomes a bottleneck, mount it behind auth and access it sparingly.

## Still stuck?

Open an issue at <https://github.com/S13G/docit/issues> with your Docit version, Rails version, and a minimal `doc_for` / route example.

<!-- markdownlint-disable MD013 MD024 -->
# 03 — Documentation Overhaul

The bundler-template `README.md` (see `README.md:5`, `README.md:25`) still
contains `TODO` placeholders. v1 must ship a complete, navigable set of docs.

## Deliverables

### D1. Top-level `README.md` rewrite

- [x] Replace the body with:
  - One-paragraph elevator pitch (matches `00-overview.md`).
  - Status badges (CI, Gem version, downloads, license, Ruby versions).
  - Install instructions (`bundle add assistant` and `gem install assistant`).
  - 60-second example: a `CreateUser` service with one required input, one
    optional input, a `validate` hook, and `execute` that returns the result.
  - "Why another service-object gem?" — three bullets contrasting with
    competitors (Interactor, dry-transaction, Trailblazer Operation): no
    runtime deps, soft-fail, tiny surface.
  - Link to `docs/getting-started.md` and `docs/api-reference.md`.
  - "Roadmap" section linking to `docs/v1/README.md`.
  - Keep the existing License + Code of Conduct sections.
- [x] Remove every `TODO:` placeholder (`README.md:5`, `README.md:25`).
- [x] Replace `https://github.com/[USERNAME]/assistant` with
      `https://github.com/ramongr/assistant` (`README.md:35`,
      `README.md:43`).

> Documentation index links point at `docs/v1/01-api-surface.md` and the
> existing planning docs until D2/D3 land the user-facing
> `docs/getting-started.md` and `docs/api-reference.md` siblings. The
> README will be re-linked as part of the D2 PR.

### D2. New user-facing pages under `docs/` (siblings of `docs/v1/`)

| File                                  | Contents                                                                  |
|---------------------------------------|---------------------------------------------------------------------------|
| `docs/getting-started.md`             | Install, first service, running it, reading the result hash, status enum. |
| `docs/guides/inputs.md`               | `input` / `inputs`, type checks, `required:`, `optional:`, `if:`, `default:`, `allow_nil:`, multi-type; "Using `bin/assistant-rbs`" subsection (M11) explaining the per-class RBS generator and R1's metaprogramming limitation. |
| `docs/guides/validation.md`           | `validate` hook, when to log warnings vs errors, conditional requirements. Note that `LogItem.new` is now strict (M10). |
| `docs/guides/logging-and-results.md`  | `LogItem` shape and **strict construction** (M10), levels, `add_log`, `merge_logs`, the `log_item_info/warning/error` shorthands (M5), `#logs` / `#warnings` / `#errors`, result hash. |
| `docs/guides/composing-services.md`   | Manual composition today; `call_service` (M-S2); error/warning propagation rules; using callbacks (M-S1) and the instrumentation notifier (M-S3); reading `#input_snapshot` (M-S4). |
| `docs/api-reference.md`               | Curated, hand-written reference of every Frozen symbol from `01-api-surface.md`. Auto-generation deferred. |
| `docs/deprecations.md`                | Created as part of M9; first entry documents the `valid_require_*?` → `valid_required_*?` deprecation. |

Each guide includes:

- A "TL;DR" callout at the top.
- A runnable Ruby snippet (copy-paste with no edits).
- A "Common pitfalls" section.
- "See also" links to siblings and to the relevant API-reference anchor.

### D3. YARD doc comments on all public methods

- [ ] Add `# @param`, `# @return`, `# @example` to every Frozen symbol in
      [`01-api-surface.md`](./01-api-surface.md).
- [ ] Add `.yardopts` configured to:
  - Source: `lib/**/*.rb`.
  - Markdown extra files: `README.md docs/**/*.md`.
  - Output: `doc/` (already gitignored if not, ensure so).
- [ ] Verify `bundle exec yard stats --list-undoc` reports 100% documented
      public methods.
- [ ] **Do not** add `yard` to runtime deps; add to development deps in
      `assistant.gemspec`.

### D4. Repository hygiene files

- [ ] `CONTRIBUTING.md`: how to clone, `bin/setup`, run `rake test` and
      `rake ci`, branch naming, commit style, PR template expectations,
      code of conduct link.
- [ ] `SECURITY.md`: supported versions table (1.x supported; 0.x EOL on
      1.0.0 release), how to report vulnerabilities (private email,
      response SLA).
- [ ] `.github/PULL_REQUEST_TEMPLATE.md`: checklist that includes
      "CHANGELOG entry added", "tests added", "docs updated".
- [ ] Confirm `CODE_OF_CONDUCT.md` contact email is current
      (`CODE_OF_CONDUCT.md` exists, last reviewed 2026-05-07).
- [ ] Confirm `README.md` and `CHANGELOG.md` link to the right repo URL.

### D5. Examples

The example set is the runnable backing for the GitHub Pages
**Examples gallery** (see [`08-github-pages.md`](./08-github-pages.md)).
Each example is shipped in its own PR (`P6`–`P12` on that plan) and
includes all three of: a runnable script under `examples/<slug>/` with
its own `README.md`, a site page under `docs/examples/<slug>.md` that
embeds the script verbatim via mkdocs `pymdownx.snippets`, and a
regression test under `test/examples/<slug>_example_test.rb`.

| Slug                       | Demonstrates                                                                                  |
|----------------------------|------------------------------------------------------------------------------------------------|
| `rails_service`            | Rails-shaped controller; `case service.run in { result:, status: :ok }`.                       |
| `cli_handler`              | `OptionParser`-driven script; exit code derived from `#status`.                                |
| `sidekiq_worker`           | Background worker that runs a service; idempotent; warnings vs errors separated.               |
| `composing_services`       | Outer service composes two inner services via `call_service`; log timeline merging.            |
| `execute_callbacks`        | `before_execute` audit logger; `around_execute` timing wrapper; failure-path behavior.         |
| `instrumentation_notifier` | `Assistant.notifier=` wired to a fake `ActiveSupport::Notifications`-shaped sink.              |
| `rbs_generator`            | Service definition → `bin/assistant-rbs --output sig` → Steep proving the per-input return type. |

- [ ] Each example has its own `README.md` linking back to
      `docs/getting-started.md` and to its rendered site page.
- [ ] The legacy `examples/greeter.rb` (used by the M11 Steep fixture)
      stays where it is and is **not** restructured into an example
      directory; it pre-dates this catalogue and serves a different
      purpose (generator regression).

## Acceptance criteria

- [ ] `README.md` renders cleanly on rubygems.org and github.com.
- [ ] No `TODO:` strings remain in `README.md`.
- [ ] Every link in `docs/**/*.md` is reachable
      (`bundle exec rake docs:check_links` — implementation deferred; manual
      pass acceptable for 1.0).
- [ ] `bundle exec yard stats --list-undoc` reports 100% documented public
      methods.
- [ ] Each guide page has at least one tested example: every code block
      tagged ```` ```ruby ```` in `docs/getting-started.md` and
      `docs/guides/*.md` is mirrored by an integration test in
      `test/docs/<guide>_examples_test.rb` (a new directory).

## Out of scope for v1 docs

- Translated docs.
- Auto-generated API reference from YARD; the curated `api-reference.md` is
  enough for 1.0.

A GitHub Pages site (mkdocs-material) **is** in scope as a parallel
deliverable tracked in [`08-github-pages.md`](./08-github-pages.md). It
does not block the 1.0 tag; the README links at the in-repo Markdown
until the site is live.

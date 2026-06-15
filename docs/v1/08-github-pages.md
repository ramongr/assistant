<!-- markdownlint-disable MD013 MD024 -->
# 08 — GitHub Pages Site

Parallel deliverable that lifts the "no docs site generator" non-goal
originally stated in [`00-overview.md`](./00-overview.md) and
[`03-documentation.md`](./03-documentation.md). The site **does not block**
the 1.0 tag — it ships on its own track and goes live whenever the
content is ready. The 1.0 README links at the in-repo Markdown until
then, and gains an "Online docs" link in a follow-up once Pages is live.

## Stack decisions (locked)

| Decision           | Choice                                                                 | Rationale                                                                                              |
|--------------------|------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------|
| Generator          | [mkdocs](https://www.mkdocs.org/) + [mkdocs-material](https://squidfunk.github.io/mkdocs-material/) | Polished out of the box: client-side search, dark mode, copy-code button, content tabs, mermaid.       |
| Deploy             | GitHub Actions on push to `main`; deploys to GitHub Pages.             | No long-running build server. Uses `actions/configure-pages` + `actions/deploy-pages`.                 |
| Hosting            | `https://ramongr.github.io/assistant/`                                 | Default GitHub Pages URL; no custom domain in 1.0.                                                     |
| Content source     | The same Markdown files under `docs/` that D2 ships.                   | Single source of truth: GitHub renders the files; mkdocs renders the site.                            |
| Theme              | Material, default palette + indigo accent, light/dark toggle.          | No custom CSS in v1; revisit only if a clear branding decision lands.                                 |
| Versioning         | Single live version (no `mike`).                                       | Premature for 1.0. Add versioned docs in the first minor that ships a breaking change behind a flag.   |
| Search             | Material built-in `search` plugin.                                     | Zero-config, client-side, works offline.                                                              |
| Diagrams           | Material `pymdownx.superfences` + `mermaid2` plugin.                   | We have at least the run-lifecycle diagram + the call_service composition diagram in mind.            |
| Code highlighting  | Material `pymdownx.highlight` + `pymdownx.inlinehilite`.               | Ruby + console syntaxes; copy button enabled.                                                          |
| Python toolchain   | Pinned in `requirements-docs.txt`. CI uses `actions/setup-python@v5`.  | Reproducible local + CI builds.                                                                       |
| Live preview       | `bundle exec rake docs:serve` wraps `mkdocs serve` for parity.         | Ruby contributors don't have to remember the Python command.                                          |

## Site map

| Path                                | Source                                                | Contents                                                                 |
|-------------------------------------|-------------------------------------------------------|--------------------------------------------------------------------------|
| `/`                                 | `docs/index.md` (new — landing page)                  | Elevator pitch, install, tiny example, prominent links into the guides.  |
| `/getting-started/`                 | `docs/getting-started.md` (from D2)                   | Install, first service, reading the result hash, status enum.            |
| `/guides/inputs/`                   | `docs/guides/inputs.md` (from D2)                     | `input` / `inputs`, type checks, `required:` / `if:` / `default:` / `allow_nil:`. |
| `/guides/validation/`               | `docs/guides/validation.md` (from D2)                 | `validate` hook; warnings vs errors; strict `LogItem.new` (M10).         |
| `/guides/logging-and-results/`      | `docs/guides/logging-and-results.md` (from D2)        | `LogItem`, levels, `add_log`, `merge_logs`, `log_item_*` shorthands.     |
| `/guides/composing-services/`       | `docs/guides/composing-services.md` (from D2)         | `call_service` (M-S2); callbacks (M-S1); notifier (M-S3); snapshot (M-S4). |
| `/guides/rbs-and-types/`            | `docs/guides/rbs-and-types.md` (new — required by site) | Per-class generator (M11); R1 metaprogramming limitation; Steep CI hookup. |
| `/api-reference/`                   | `docs/api-reference.md` (from D2/D3)                  | Curated, hand-written reference of every Frozen symbol.                  |
| `/deprecations/`                    | `docs/deprecations.md` (exists)                       | `valid_require_*?` → `valid_required_*?` (M9), future entries.           |
| `/examples/`                        | `docs/examples/index.md` (new — gallery index)        | Card grid linking to each example writeup.                               |
| `/examples/rails-service/`          | `docs/examples/rails-service.md` (new) + `examples/rails_service/` (D5) | Rails-shaped controller calling a service; pattern-match on result hash. |
| `/examples/cli-handler/`            | `docs/examples/cli-handler.md` (new) + `examples/cli_handler/` (D5)    | `OptionParser`-driven script; exit code from `#status`.                  |
| `/examples/sidekiq-worker/`         | `docs/examples/sidekiq-worker.md` (new) + `examples/sidekiq_worker/` (new) | Background job that runs a service; idempotent, no exceptions for expected failures. |
| `/examples/composing-services/`     | `docs/examples/composing-services.md` (new) + `examples/composing_services/` (new) | Outer service uses `call_service` to chain two inner services; log timeline merging. |
| `/examples/execute-callbacks/`      | `docs/examples/execute-callbacks.md` (new) + `examples/execute_callbacks/` (new) | `before_execute`, `after_execute`, `around_execute`; timing wrapper, audit logger. |
| `/examples/instrumentation-notifier/` | `docs/examples/instrumentation-notifier.md` (new) + `examples/instrumentation_notifier/` (new) | `Assistant.notifier=` wired to a fake `ActiveSupport::Notifications`-shaped sink. |
| `/examples/rbs-generator/`          | `docs/examples/rbs-generator.md` (new) + `examples/rbs_generator/` (new) | Service + generated `.rbs` + Steep config showing per-input return types. |
| `/roadmap/`                         | re-uses [`README.md`](./README.md) (the v1 planning index) | Roadmap status snapshot, links into the v1 planning docs.                |
| `/changelog/`                       | re-uses [`../../CHANGELOG.md`](../../CHANGELOG.md)    | Same Keep-A-Changelog file, rendered.                                    |

## Deliverables (each a separate PR)

### P1. Plan and reconciliation _(this PR)_

- [x] Land this `08-github-pages.md` planning document.
- [x] Update [`00-overview.md`](./00-overview.md) non-goals to reflect that
      a docs site **is** in scope as a parallel track, not as a 1.0 gate.
- [x] Update [`03-documentation.md`](./03-documentation.md) "Out of scope"
      to drop the docs-site-generator line and cross-link here.
- [x] Update [`03-documentation.md`](./03-documentation.md) D5 to enumerate
      all 7 example directories (was 2; user expanded the showcase scope
      when the GitHub Pages plan landed).
- [x] Update [`./README.md`](./README.md) plan index with row 08.

### P2. mkdocs scaffolding + deploy pipeline

Goal: every push to `main` deploys the site, even if content is mostly
placeholder.

- [ ] `mkdocs.yml` at repo root: site name, `theme: name: material`, palette
      with light/dark toggle, repo URL + edit-this-page links, navigation
      tree matching the **Site map** table.
- [ ] `requirements-docs.txt`: pinned `mkdocs`, `mkdocs-material`,
      `mkdocs-material-extensions`, `mkdocs-mermaid2-plugin`,
      `pymdown-extensions`.
- [ ] Placeholder Markdown stubs for every site-map entry that does not
      yet exist (each carries a one-line "Coming in PR Pn" note).
- [ ] `.github/workflows/docs.yml`: triggers on push to `main` (paths
      `docs/**`, `mkdocs.yml`, `requirements-docs.txt`, the workflow
      itself). Steps: `actions/setup-python@v5`, install requirements,
      `mkdocs build --strict`, `actions/configure-pages`,
      `actions/upload-pages-artifact`, `actions/deploy-pages`. Permissions:
      `pages: write`, `id-token: write`. Concurrency group `pages` with
      `cancel-in-progress: false`.
- [ ] Enable GitHub Pages source = "GitHub Actions" in repo settings
      (one-time manual step; note in CHANGELOG release-engineering).
- [ ] `Rakefile` `docs:serve` and `docs:build` tasks that shell out to
      `python -m mkdocs serve` / `build` after `pip install -r
      requirements-docs.txt`.
- [ ] Verify the deployed site renders at
      `https://ramongr.github.io/assistant/` with the nav tree intact.

### P3. Landing page + getting-started + roadmap surface

- [ ] `docs/index.md` (landing): pulls the elevator pitch, install
      blurb, the tiniest possible runnable snippet, and the four primary
      CTAs (Getting started · Guides · API reference · GitHub).
- [ ] `docs/getting-started.md` (was a D2 deliverable; landed here as part
      of this PR if D2 hasn't already shipped it).
- [ ] Wire the `/roadmap/` route to render the existing
      [`./README.md`](./README.md) via mkdocs `nav` aliasing
      (`- Roadmap: ../v1/README.md` or via a generated stub that includes
      the file).
- [ ] Same for `/changelog/` → root `CHANGELOG.md`.

### P4. Guides migration

- [ ] Move (or co-author with D2) the five guide pages listed in the
      **Site map** under `docs/guides/`.
- [ ] Add the new `docs/guides/rbs-and-types.md` page (M11 + R1 + Steep
      CI hookup); not in the original D2 outline because D2 folds RBS
      into `docs/guides/inputs.md`. Splitting out is cleaner once the
      site has a left-nav.
- [ ] Each guide opens with the "TL;DR / runnable snippet / common
      pitfalls / see also" pattern mandated by D2.

### P5. API reference

- [ ] `docs/api-reference.md` curated reference of every Frozen symbol
      in [`01-api-surface.md`](./01-api-surface.md), one anchor per
      symbol, deep-link friendly. **Hand-written**, not YARD-generated
      (matches D2 decision).

### P6–P12. Examples (one PR per example)

Each example PR ships **all three** of:

1. Runnable script(s) under `examples/<slug>/` with a `README.md` whose
   first sentence describes the problem the example solves.
2. A site page under `docs/examples/<slug>.md` that includes the script
   verbatim via mkdocs `pymdownx.snippets` (so the rendered prose stays
   in sync with the runnable code).
3. A regression test under `test/examples/<slug>_example_test.rb` that
   `require_relative`s the script in a sandboxed namespace and asserts
   on its result hash.

| PR  | Example                  | Demonstrates                                                                          |
|-----|--------------------------|---------------------------------------------------------------------------------------|
| P6  | `rails_service`          | Rails-shaped controller; `case service.run in { result:, status: :ok }`.              |
| P7  | `cli_handler`            | `OptionParser` driving a service; exit code derived from `#status`.                   |
| P8  | `sidekiq_worker`         | Worker class that runs a service; idempotent; logs warnings vs errors separately.     |
| P9  | `composing_services`     | Two inner services + outer service using `call_service`; log timeline merging.        |
| P10 | `execute_callbacks`      | `before_execute` audit logger; `around_execute` timing wrapper; failure cases.        |
| P11 | `instrumentation_notifier` | `Assistant.notifier=` wired to a fake `ActiveSupport::Notifications` sink.          |
| P12 | `rbs_generator`          | Service definition → `bin/assistant-rbs --output sig` → Steep proving the per-input return type. |

### P13. README online-docs link

- [ ] Once the site is live and the **Site map** routes resolve, edit the
      top-level [`README.md`](../../README.md) to add a "**Online
      documentation:** `https://ramongr.github.io/assistant/`" callout
      above the Documentation section and to flip the inline
      documentation index over to the deployed URLs.
- [ ] Update `assistant.gemspec`
      `spec.metadata['documentation_uri']` from the placeholder
      `https://rubydoc.info/gems/assistant` (per
      [`04-release-checklist.md`](./04-release-checklist.md) D-checklist)
      to the live Pages URL.

## Acceptance criteria

- [ ] `mkdocs build --strict` passes locally and in CI.
- [ ] `https://ramongr.github.io/assistant/` returns 200 and renders the
      full nav.
- [ ] Every page in the **Site map** exists (placeholder is acceptable
      after P2; real content after the matching Pn).
- [ ] Every code block tagged ```` ```ruby ```` in `docs/getting-started.md`,
      `docs/guides/*.md`, and `docs/examples/*.md` either is included
      via `pymdownx.snippets` from a file under `examples/` **or** is
      mirrored by an integration test under `test/docs/` /
      `test/examples/` (the D2 acceptance criterion, extended to the
      example pages).
- [ ] Search box returns sensible results for "input", "warnings",
      "call_service", "notifier", "RBS".
- [ ] Dark-mode toggle works; no theme-specific custom CSS in v1.
- [ ] Repo-edit-this-page link on every page points at the right file on
      `main`.

## Out of scope (deferred)

- Custom domain.
- Versioned docs via `mike` (revisit when the first 2.x change lands).
- Auto-generated YARD API reference (curated `api-reference.md` is enough).
- A blog / changelog feed beyond the rendered `CHANGELOG.md`.
- Translated docs.
- Analytics / cookie consent.
- Custom theme branding (logo, favicon, palette tweaks) — left for a
  follow-up once the content is in place.

## Cross-references

- [`00-overview.md`](./00-overview.md) — non-goals updated to allow this track.
- [`03-documentation.md`](./03-documentation.md) — D2 source files, D5
  examples list expanded to 7.
- [`04-release-checklist.md`](./04-release-checklist.md) — does **not**
  gain a Pages-deployed gate for the 1.0 tag.

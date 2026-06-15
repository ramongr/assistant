<!-- markdownlint-disable MD043 -->
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed

- **GitHub Pages — fix 9 broken in-page anchor links**: the API
  reference's own table of contents and four guide pages linked
  to API reference headings using the pre-Docsify Marked.js
  slugger output (`#assistantservice`, `#assistantlogitem`,
  `#assistantloglist`), which *stripped* the `::` separator.
  Docsify's slugger *replaces* `:` with `-`, producing
  `#assistant-service`, `#assistant-logitem`, `#assistant-loglist`,
  so every one of those links scrolled to the top of the page
  instead of the target section. Same root cause for
  `examples/rbs-generator.md` → `guides/inputs.md` which still
  used the legacy heading slug `#using-binassistant-rbs-for-steep-users`
  after the heading was renamed to `## Using \`assistant-rbs\` for
  Steep users` (now `#using-assistant-rbs-for-steep-users`). All
  nine links updated; verified by hitting each anchor against
  `bundle exec rake docs:serve`. No HTTP 404s exist anywhere in
  the served Examples nav (already confirmed in #190 and re-verified
  here).

- **GitHub Pages — light-mode inline `code` is readable**: the
  light theme passed `highlightColor: '#ffd166'` Naples Yellow to
  docsify-darklight-theme. That property controls the **text color
  of inline `<code>` tags** in markdown (the plugin's CSS sets
  `.markdown-section code { color: var(--highlightColor) }`), which
  renders on the `#ffffff` code background at **1.43:1** contrast —
  essentially invisible. Every inline `code` snippet across the
  docs site was unreadable in light mode. Swapped to `#2f4f5a`
  Steel Teal Dark (matching the link accent), giving **8.30:1** on
  white — comfortably AAA. Dark mode is unchanged; `#ffd166`
  remains the dark-theme primary accent (12:1 on `#22223b`) and
  the dark-cover gradient endpoint. Naples Yellow is no longer
  referenced anywhere in the light-theme palette.

- **GitHub Pages — light-mode accent passes WCAG AAA**: the
  previous light-mode primary accent `#4d7c8a` Steel Teal cleared
  WCAG AA-large (3:1) but only reached 4.07:1 on the `#f4f2f3`
  background, just shy of AA-normal (4.5:1) for body-text links.
  Introduced `#2f4f5a` Steel Teal Dark as a derived shade — same
  hue family, 7.87:1 contrast on `#f4f2f3`, comfortably AAA.
  Replaced the light-theme `accent`, `codeTypeColor`,
  Docsify `themeColor`, inline `--theme-color`, and the
  `<meta name="theme-color">` mobile address-bar color. Dark mode
  is untouched — `#4d7c8a` stays as the dark-theme highlight and
  the brand-asset color (logo, OG card).

- **GitHub Pages — render Mermaid diagrams**: the
  `docsify-mermaid@2` plugin was loaded from the package root
  (`//cdn.jsdelivr.net/npm/docsify-mermaid@2`), which jsDelivr
  resolves to an ES-module source file (`src/index.js`). The browser
  refused to execute it as a classic script, the plugin never
  registered, and every fenced ```` ```mermaid ```` block on the
  site (landing page, getting started, api reference, validation
  guide, GitHub Pages spec) rendered as raw flowchart text inside a
  `<pre><code>` instead of as a diagram. Pinned to the UMD bundle
  at `/dist/docsify-mermaid.js` (5 KB, no `import` statements);
  diagrams now render on every page.

- **GitHub Pages — revert to hash routing**: clean URLs from the
  history-mode experiment (`routerMode: 'history'` + `basePath:`)
  returned HTTP 404 on GitHub Pages even though the `docs/404.html`
  SPA fallback rendered the right page. The 404 status broke link
  previews, link checkers, and search crawlers. Reverted to Docsify's
  default hash routing (`/assistant/#/getting-started`); every
  navigable URL now resolves with HTTP 200. `docs/404.html` is kept
  as a copy of `docs/index.html` so stale history-mode URLs still
  land on a usable docs page. `rake docs:serve` no longer needs the
  SPA-fallback servlet.

### Changed

- **GitHub Pages — drop Roadmap and Changelog from the public nav**:
  the sidebar (`docs/_sidebar.md`) and the "Where to next" table
  on the landing page (`docs/index.md`) both used to list
  Roadmap and Changelog as primary destinations. Both are
  contributor-facing artefacts — the roadmap tracks internal
  milestone planning, and the changelog is the verbatim
  `Keep a Changelog` history used for releases — neither tells a
  reader how to use the gem. Removed both entries from the sidebar
  and from the landing-page table. The pages themselves still live
  under `docs/roadmap.md` and `docs/changelog.md` and remain
  reachable by direct URL (the self-link in `roadmap.md` and the
  release-process tooling in `docs/v1/*` still resolve), they're
  just no longer surfaced as navigation.

- **GitHub Pages — drop internal milestone tags from public copy**:
  the user-facing docs (api reference, deprecations, roadmap,
  every guide page) used to suffix headings and prose with
  internal roadmap identifiers like `(M3)`, `(M-S1)`, or `(M10)`.
  Those tags are meaningful only to contributors who built the v1
  plan; to readers they're noise. Stripped them from 9 pages,
  renamed 8 headings to drop the suffix (e.g.
  `## default: (M1)` → `## default:`, `## Execute callbacks (M-S1)`
  → `## Execute callbacks`), and updated the 3 inbound anchor
  links accordingly. The internal `docs/v1/*` working docs (not in
  the sidebar, but reachable by direct URL) are left as-is — they
  are the milestone-tracking working set.

- **GitHub Pages — light-mode link color + nav cleanup**: the light
  theme now uses `#4d7c8a` Steel Teal as the primary accent (links,
  Docsify `themeColor`, browser address bar) instead of `#ffd166`
  Naples Yellow, which failed AA contrast against the `#f4f2f3`
  background. Yellow is reassigned to `highlightColor` so it still
  highlights the active sidebar entry and search matches. Dark mode
  is unchanged — yellow stays the primary accent against the
  Space Cadet background. Also dropped the `[YARD docs]` sidebar
  link (the gem ships RBS, not YARD-rendered Ruby source, so the
  link pointed at an empty rubydoc.info page).

- **GitHub Pages — regenerate favicon + apple-touch-icon from new
  brand SVG**: rasterized `docs/_media/home-logo.svg` (Space Cadet
  rounded square with a Naples Yellow `A` glyph) into
  `docs/_media/favicon.png` (32×32) and
  `docs/_media/apple-touch-icon.png` (180×180), replacing the legacy
  PNGs that still carried the old `#009ffd` Vivid Sky Blue accent.
  `docs/_media/repo-card.png` (1200×630 OG card) has no SVG source
  in the tree and still needs external regeneration.

- **GitHub Pages — small content polish**: dropped a stale "Jekyll
  site" reference in `docs/roadmap.md` (we've been on Docsify since
  PR #187) and scrubbed an internal `(M-D2.1)` post-mortem tag from
  the `docs/index.html` / `docs/404.html` JavaScript comment block
  about hash routing. Public-facing wording only — no behavior
  change.

- **GitHub Pages — brand palette refresh**: swap the secondary
  accent / highlight / primary accent to
  [`22223b-a07178-4d7c8a-f4f2f3-ffd166`](https://coolors.co/22223b-a07178-4d7c8a-f4f2f3-ffd166).
  Roles: `#22223b` Space Cadet (dark), `#a07178` Rose Taupe
  (secondary), `#4d7c8a` Steel Teal (highlight), `#f4f2f3` Cultured
  (light bg), `#ffd166` Naples Yellow (primary accent, replaces the
  former Vivid Sky Blue `#009ffd`). Applied to `docs/index.html`,
  `docs/404.html`, and `docs/_media/home-logo.svg`. The
  `favicon.png` and `apple-touch-icon.png` are regenerated from the
  refreshed SVG further down in this Unreleased section; the
  `repo-card.png` (1200×630 OG card) still carries the old blue
  accent and needs external regeneration.

- **GitHub Pages — swap stack from Jekyll to Docsify**: replace the
  Jekyll + just-the-docs site (shipped in PR #180) with a Docsify
  client-side SPA matching the UX of
  <https://lostisland.github.io/faraday/#/>. The new stack:
  - Removes ~5 Ruby gems (`jekyll`, `jekyll-relative-links`,
    `just-the-docs`, `jekyll-seo-tag`, `jekyll-include-cache`) plus
    transitive deps (`kramdown`, `rouge`, `sass-embedded`, `webrick`,
    `addressable`, `em-websocket`, `eventmachine`, etc.) from
    `Gemfile.lock` — 104 lines deleted.
  - Removes the 87 sass `darken()` deprecation warnings that came
    from just-the-docs internals on every build.
  - Removes the entire local docs toolchain step; `rake docs:serve`
    now runs `ruby -run -e httpd docs -p 4000` (stdlib WEBrick) —
    no `bundle install --with docs`, no Sass, no node, no Python.
  - Loads every plugin (theme, search, syntax highlighting, mermaid,
    edit-on-github, copy-code, tabs) from `cdn.jsdelivr.net` at
    runtime. The Pages workflow uploads `docs/` verbatim — no build
    step.
  - Adopts the new brand palette: `#22223b` (Space Cadet) /
    `#a07178` (Rose Taupe) / `#4d7c8a` (Steel Teal) / `#f4f2f3`
    (Cultured) / `#ffd166` (Naples Yellow, primary accent). Logo,
    OG card, favicons regenerated.
  - URL shape changes from `/getting-started.html` → `/#/getting-started`
    (hash-routed SPA). The site was only hours old; no external links
    to redirect.

### Fixed

- **GitHub Pages — restore default layout on every internal page**:
  add a `defaults:` block to [`_config.yml`](_config.yml) that applies
  just-the-docs's `layout: default` to every page that doesn't
  declare its own layout. Before this fix, only the homepage
  (`layout: home`) rendered with the full chrome — every other page
  (Getting started, Guides, API reference, Examples, Roadmap,
  Changelog, Deprecations and all their children) was emitted as a
  raw `<h1>…</h1>` body fragment with no sidebar, header, search
  input, sub-nav, copy buttons, dark-mode toggle, footer, or
  baseurl-aware navigation. Latent since PR #180; the homepage
  redesign in PR #185 made the contrast visible.

### Added

- **GitHub Pages — home page redesign**: replace the bare
  [`docs/index.md`](docs/index.md) landing with a richer page —
  primary/secondary CTA buttons (built on just-the-docs's `.btn`
  utilities), a three-column "Why Assistant?" value-prop strip
  (soft-fail / zero deps / typed + Steep-ready), a Mermaid
  lifecycle teaser ("How a service flows"), the install + 60-second
  example blocks, and a "Where to next" navigation grid that
  surfaces every top-level page (including Deprecations).

- **GitHub Pages — examples gallery rewrites**: replace the seven
  `docs/examples/<slug>.md` P6–P12 placeholders with self-contained,
  callout-sized code patterns covering Rails controllers, CLI
  handlers, Sidekiq workers, composed services, execute callbacks,
  the instrumentation notifier, and `bin/assistant-rbs`. Each page
  still calls out which P6–P12 milestone will ship the runnable
  script + regression test, but the prose is now useful on its own.

- **GitHub Pages — Mermaid diagrams**: render the result-status
  decision flow on [`docs/getting-started.md`](docs/getting-started.md)
  and [`docs/api-reference.md`](docs/api-reference.md), plus the full
  per-request lifecycle (defaults → declarative validators → `#validate`
  → execute → notifier hooks) on
  [`docs/guides/validation.md`](docs/guides/validation.md). Uses the
  Mermaid loader enabled in the site-polish bundle (just-the-docs
  auto-injects the ESM importer once `mermaid:` is set in
  [`_config.yml`](_config.yml)).

- **GitHub Pages — site polish bundle**: dark-mode toggle button
  (wired through `docs/_includes/head_custom.html` +
  `docs/_includes/nav_footer_custom.html` with `localStorage`
  persistence on top of just-the-docs's `jtd.setTheme()` API),
  `enable_copy_code_button` for every code block, named callouts
  (`note`/`tip`/`warning`/`important`) via `callouts:` in
  [`_config.yml`](_config.yml), Mermaid loader pinned to `10.9.1`,
  baseurl-aware favicons (SVG, 32-px PNG, 180-px apple-touch) and a
  1200×630 OG / Twitter card image under
  [`docs/assets/images/`](docs/assets/images/), and a custom
  `_includes/footer_custom.html`. Also rewrites the install snippet on
  the Home page so the visible default pins the `1.0.0.rc1`
  pre-release explicitly (the `~> 1.0` snippet kicks in once the
  stable tag ships), and filters the upstream sass `darken()`
  deprecation noise out of the Docs CI log (real build errors still
  surface via `set -o pipefail`).

- **GitHub Pages — P2 scaffolding (Jekyll + just-the-docs)**: stood up
  the parallel docs site per
  [`docs/v1/08-github-pages.md`](docs/v1/08-github-pages.md). Ships
  `_config.yml` (just-the-docs theme, Lunr search, dark-mode toggle,
  `gh_edit_link`, `jekyll-seo-tag` + `jekyll-relative-links` plugins),
  an optional `:docs` Bundler group in [`Gemfile`](Gemfile) pinning
  `jekyll ~> 4.3`, `just-the-docs ~> 0.10`, and
  `jekyll-relative-links ~> 0.7`, the
  [`.github/workflows/docs.yml`](.github/workflows/docs.yml) workflow
  (PR builds `bundle exec jekyll build --strict_front_matter`; pushes
  to `main` deploy via `actions/deploy-pages@v4`), `docs:install` /
  `docs:build` / `docs:serve` Rake tasks driving the Jekyll
  toolchain, per-page front matter on every site page (Home, Getting
  started, Guides + 5 sub-pages, API reference, Deprecations, Examples
  + 7 sub-pages, Roadmap, Changelog), and a new `docs/guides/index.md`
  landing for the Guides section. The site builds locally with `rake
  docs:build` and deploys to `https://ramongr.github.io/assistant/` on
  every push to `main`. Pages source = `GitHub Actions` was enabled in
  repo settings after the original mkdocs PR (#177) merged; no further
  manual step is needed for the Jekyll cut-over.

  _This entry supersedes the original mkdocs-based P2 scaffolding —
  the mkdocs stack lived for one PR before being replaced with Jekyll
  to match the gem's primary toolchain, drop the Python build
  dependency, and avoid the `Pygments==2.19.1` pin that worked around
  a 2.20.0 `HtmlFormatter` regression._

## [1.0.0.rc1] - 2026-06-15

### Added

- **D2 (follow-up)**: four user-facing guides under `docs/guides/` —
  [`inputs.md`](docs/guides/inputs.md),
  [`validation.md`](docs/guides/validation.md),
  [`logging-and-results.md`](docs/guides/logging-and-results.md),
  [`composing-services.md`](docs/guides/composing-services.md).
  Each guide is mirrored by a `test/docs/<guide>_examples_test.rb`
  integration test so the runnable examples can't silently drift from
  the actual behaviour. `inputs.md` includes the "Using
  `bin/assistant-rbs` for Steep users" subsection that closes the R1
  user-facing-note item in
  [`docs/v1/05-quality-and-tooling.md`](docs/v1/05-quality-and-tooling.md).
  `.yardopts` extra-files list extended to include the four new pages
  so they ship with the rendered YARD output.

- **bin/ smoke**: new `bin-smoke` job in `.github/workflows/ci.yml`
  exercises `bin/setup` against a cold bundle, syntax-checks the three
  developer scripts (`bash -n bin/setup`, `ruby -c bin/{console,version}`),
  runs `bin/version --help`, and pipes a short ruby snippet through
  `bin/console` to confirm `Assistant::VERSION` resolves. Closes the
  `bin/` smoke item in
  [`docs/v1/05-quality-and-tooling.md`](docs/v1/05-quality-and-tooling.md).
  [`CONTRIBUTING.md`](CONTRIBUTING.md) gains a `bin/ developer scripts`
  section documenting each script's purpose and noting that none of the
  three ship in the packaged gem (only `exe/assistant-rbs` does).

### Changed

- **Release prep**: gemspec polished for the 1.0 cut. `spec.summary`
  rewritten to match the README elevator pitch
  (`Tiny, dependency-free soft-fail service objects for Ruby`),
  `spec.description` expanded into a 3-sentence heredoc covering
  soft-fail semantics, the uniform result shape, the RBS / Steep
  posture, and the zero-runtime-deps guarantee. Added
  `spec.metadata['documentation_uri']`
  (`https://rubydoc.info/gems/assistant`) and
  `spec.metadata['bug_tracker_uri']`
  (`https://github.com/ramongr/assistant/issues`). The `spec.files`
  glob now excludes `examples/`, `docs/v1/`, and `docs/v1.x/` from the
  packaged gem so internal planning material and runnable samples no
  longer ship to RubyGems (Q9 decision in
  [`docs/v1/07-risks-and-open-questions.md`](docs/v1/07-risks-and-open-questions.md)).
  No behaviour change; `Assistant::VERSION` is unchanged.

### Changed (Breaking)

- **M12**: `LogList#merge_logs` and every internal
  `Assistant::InputBuilder` helper now take their name / list
  parameter as a keyword argument (`logs:` / `name:` / `names:`)
  instead of a leading positional. The two public DSL entry points
  `Service.input` and `Service.inputs` are **deliberately exempt** —
  `input :foo, type: X` reads better as a class-body declaration than
  `input name: :foo, type: X`, so their leading positional `attr_name`
  / `attr_names` stays. Hard break for the rest, no runtime shim:
  - `Service.input(:foo, type: String)` — **unchanged**
  - `Service.inputs(%i[a b], type: Integer)` — **unchanged**
  - `host.merge_logs(other.logs)` → `host.merge_logs(logs: other.logs)`
  The old positional `merge_logs` raises `ArgumentError` at call time
  ("wrong number of arguments ... required keyword: logs"). For users
  who don't compose log lists directly (i.e. who only use
  `Service#call_service` for service composition), no source change is
  required. Migration is mechanical and `git grep`-able; see
  [`docs/v1/06-migration-0x-to-1.md`](docs/v1/06-migration-0x-to-1.md).
  The full helper sweep also touches the M13-split per-concern
  modules: `process_default_option`, `validate_default!`,
  `warn_on_mutable_default`, `process_optional_option`,
  `validate_optional!`, `register_input_definition`, `input_getter_meth`,
  `input_checker_meth`, `input_type_validator_meth`, `type_validator_body`,
  `type_mismatch_message_builder`, `input_require_validator_meth`,
  `input_require_conditional_meth`, and the two private
  `RequireValidator#define_required_(conditional_)?validator` helpers
  are all keyword-only. Internal-only `Service#input_supplied?` keeps
  its positional shape (private, not part of the documented surface).
  RBS signatures across `lib/assistant/input_builder/*.rbs` (other than
  `dsl.rbs`) and `lib/assistant/log_list.rbs` updated to match.

### Added

- **D2** (entry pages): shipped `docs/getting-started.md` and
  `docs/api-reference.md`. `docs/getting-started.md` walks from
  `gem install` to a working `CreateUser` service across three runs
  (one `:ok`, one `:with_warnings`, one `:with_errors`) and links out
  to the four follow-up guides. `docs/api-reference.md` is the
  hand-written, curated reference for every Frozen symbol on
  `Assistant`, `Assistant::Service`, `Assistant::LogItem`,
  `Assistant::LogList`, the execute callbacks, `#call_service`,
  the notifier, `#input_snapshot`, and the `assistant-rbs` CLI;
  `docs/v1/01-api-surface.md` remains the source of truth for
  stability labels. `README.md` documentation index and the
  `.yardopts` extra-files list now include both new pages. The four
  topic guides (`inputs.md`, `validation.md`, `logging-and-results.md`,
  `composing-services.md`) ship in a follow-up D2 PR alongside
  `test/docs/` example tests.
- **D3**: every public Frozen symbol enumerated in
  [`docs/v1/01-api-surface.md`](docs/v1/01-api-surface.md) now carries
  YARD documentation (`@param`, `@return`, `@raise`, `@example` where
  meaningful). Internal helpers are documented too, so
  `bundle exec yard stats --list-undoc` reports **100%** documented
  public methods (52 / 52, plus 7 / 7 attributes and 9 / 9 constants).
  Shipped together with a top-level `.yardopts` (markdown markup,
  `lib/**/*.rb` as the source, README + repo-hygiene files as extra
  files), the new `yard` development dependency in `assistant.gemspec`,
  and a `rake yard` task that builds the site into `doc/` and exits
  non-zero if coverage drops below 100%. `rake ci` now runs
  `test + rubocop + steep + yard`.
- **D4**: shipped the repository-hygiene files called for in
  [`docs/v1/03-documentation.md`](docs/v1/03-documentation.md). New
  `CONTRIBUTING.md` documents the clone / `bin/setup` flow, the local
  pipeline (`rake test`, `rubocop`, `steep check`, `rake ci`), branch
  naming, commit-tag conventions, and PR template expectations. New
  `SECURITY.md` declares 1.x as the supported line, 0.x as EOL on the
  `1.0.0` release, gives `cerberus.ramon@gmail.com` as the private
  report channel, and commits to a 7-day first-response /
  30-day-fix-or-mitigation-plan SLA. New
  `.github/PULL_REQUEST_TEMPLATE.md` enforces the
  `Scope / What ships / Verification / Out of scope` body shape and the
  `CHANGELOG entry / tests added / docs updated / rake ci is green`
  checklist on every pull request.
- **D1**: rewrote the top-level `README.md`. Replaced the bundler-template
  `TODO:` placeholders and `[USERNAME]/assistant` URLs with an elevator
  pitch, status badges (CI, gem version, downloads, Ruby version,
  license), `bundle add` / `gem install` instructions, a runnable
  60-second `CreateUser` example covering required inputs, defaults,
  `allow_nil:`, `validate`, and the `log_item_warning` /
  `log_item_error` shorthands, a "why another service-object gem?"
  comparison against Interactor and dry-transaction, a documentation
  index pointing at `docs/v1/01-api-surface.md`, the migration guide,
  deprecations, examples, the changelog, and the roadmap, plus a
  refreshed Development section listing `rake test`, `rubocop`, and
  `steep check`. (D1, v1 plan)

- `Assistant::Service#input_snapshot` — returns a frozen `Data`
  instance whose members are the declared input names (via
  `Service.input` / `Service.inputs`), in declaration order, with
  values read from `@inputs` after `apply_input_defaults` has run. The
  snapshot therefore reflects post-`default:` and post-`allow_nil:`
  values, matching what the per-input getters expose. Only declared
  inputs appear; extra keyword arguments accepted by `#initialize`
  (which live in `@inputs` but have no `input :foo` declaration) are
  intentionally excluded so the snapshot's shape mirrors the public
  DSL. A declared input with no default and no caller-supplied value
  surfaces as `nil`. The returned `Data` is structurally immutable
  (no member reassignment); member values that are themselves mutable
  (e.g. an `Array`) keep their normal mutability — the snapshot does
  not deep-freeze. Each call returns a fresh `Data` instance backed
  by a per-subclass `Data` class memoised on
  `Service.input_snapshot_class` (rebuilt transparently if the
  subclass declares more inputs after the first snapshot call).
  Useful for passing a read-only view of inputs to helpers,
  collaborators, or test assertions without exposing the mutable
  `@inputs` hash.

- `Assistant::Service#call_service(klass, **inputs)` — instance-level
  helper for composing services. Constructs an instance of `klass`
  (asserted to be an `Assistant::Service` subclass; raises
  `ArgumentError` otherwise), invokes `inner.run`, merges the inner
  service's full log timeline (info + warning + error) onto the outer
  service via `merge_logs`, and returns the inner instance. Because
  `Service#errors` / `#warnings` / `#status` are derived by filtering
  `@logs`, inner errors automatically downgrade the outer terminal
  status to `:with_errors` and inner warnings surface as
  `:with_warnings` (when no errors are present), without any branching
  in the caller. Exceptions raised by the inner service's `#execute`
  or by `Assistant.notifier` are not rescued; they propagate to the
  caller, matching the base `Service#run` contract. The inner service
  fires its own `:service_started`/`:service_validated`/
  `:service_executed`/`:service_failed` events independently of the
  outer lifecycle. (M-S2, v1 plan)

- `before_execute`, `after_execute { |result| }`, and
  `around_execute { |&blk| ... }` class-level DSL on
  `Assistant::Service` for wrapping `#execute` with reusable hooks.
  Hooks are `instance_exec`'d on the service (so `self` is the service
  instance) and execute after validation in declaration order; the
  first-declared `around_execute` is the outermost layer. Hooks are
  inherited at subclass-definition time via an array snapshot — later
  additions on the parent do not bleed into existing subclasses. Errors
  raised inside any hook are caught, never propagate out of `#run`,
  and are logged via `add_log(level: :error, source: :hook, detail:
  <hook_type>, message: "<ErrorClass>: <message>", trace: backtrace)`.
  A hook-logged error downgrades the terminal lifecycle event to
  `:service_failed` and the run payload to `{ errors:, result: nil,
  status: :with_errors }`; the actual execute return value remains
  accessible via `service.result`. (M-S1, v1 plan)

- `Assistant.notifier` and `Assistant.notifier=` — module-level
  configuration accessor for an instrumentation callable. The default
  notifier is a frozen no-op lambda (`Assistant::DEFAULT_NOTIFIER`);
  the setter accepts any object responding to `#call(event, payload)`
  or `nil` to reset to the default. Passing anything else raises
  `ArgumentError` immediately. `Service#run` now fires four frozen
  events around its lifecycle: `:service_started` at entry,
  `:service_validated` after `validate_inputs` + `validate`, and
  exactly one of `:service_executed` (no logged errors) or
  `:service_failed` (errors present) before returning. Every payload
  carries `{ service_class:, duration_s: }`; `duration_s` is a `Float`
  measured against `Process::CLOCK_MONOTONIC` from the start of `#run`.
  Notifier exceptions (`StandardError`) are caught and surfaced via
  `Kernel.warn`; subsequent events still fire. (M-S3, v1 plan)

- `bin/assistant-rbs` (shipped as `exe/assistant-rbs`) — a CLI that
  loads user-supplied Ruby paths and emits an `.rbs` file per
  `Assistant::Service` subclass into a configurable output directory
  (default `sig/`). Each generated file declares the per-input getter
  (`def <name>: () -> Type`) and predicate (`def <name>?: () -> bool`)
  pairs derived from `Service.input_definitions`, including multi-type
  unions (`(A | B)`) and `allow_nil:` (`(A | B)?`). Output is marked
  with a header sentinel and is idempotent: rerunning leaves unchanged
  files alone (`[unchanged]`) and refuses to overwrite hand-written
  `.rbs` files that lack the sentinel (`[skipped]`). Namespaced classes
  are emitted with nested `module` declarations so the generated file is
  self-contained. Use `--output DIR`, `--quiet`, and `--help`. The
  generator only emits sigs for `Service` subclasses introduced by the
  paths it was asked to load (snapshot diff via `ObjectSpace`).
  An `examples/greeter.rb` + generated `sig/examples/greeter.rbs`
  fixture is type-checked by Steep as the acceptance test. The CLI
  itself is Experimental; the generated `.rbs` content tracks the
  Frozen `Service.input` surface. (M11, v1 plan)
- Hand-written RBS signatures for the frozen public surface defined in
  `docs/v1/01-api-surface.md`: `Assistant::VERSION`, `Assistant::LogItem`,
  `Assistant::LogList`, `Assistant::Service` (excluding the per-input
  methods generated by `Service.input`), `Assistant::InputBuilder` plus
  its `Registry`, `DefaultOption`, `OptionalOption`, `Accessors`,
  `RequireValidator`, `TypeValidator`, and `Dsl` submodules, and a
  namespace shim for `Assistant::Refinements::StringBlankness`. Files
  live alongside the Ruby source as `lib/**/*.rbs` and ship with the
  gem (already covered by `git ls-files`). A `Steepfile` adds a `:lib`
  target type-checked by Steep in CI; `steep check` runs against the
  subset of files that do not rely on Ruby refinements or
  `define_method`. The per-input surface generated by `Service.input`
  is documented in the RBS comments and will be emitted by
  `bin/assistant-rbs` (M11). Adds `steep` as a development dependency
  and a `steep` job to `.github/workflows/ci.yml`. (M8, v1 plan)
- `Assistant::Service.input` now accepts a `default:` option. The provider
  may be a literal value or a zero-arity `Proc`/`Lambda`; anything else
  that responds to `#call` (e.g. a `Method` object) is rejected with
  `ArgumentError` at class-definition time. Procs are invoked once per
  `Service` instance, with no arguments. A default fires when the input
  key is absent, or when the value is an explicit `nil` and the input is
  not declared `allow_nil: true` — with `allow_nil: true`, an explicit
  `nil` from the caller is honoured and the default is skipped. Defaulted values
  are subject to the same type, `required:`, and `if:` validation as
  caller-supplied values. Mutable literal defaults (unfrozen `Array` /
  `Hash`) emit a `Kernel.warn` at class-definition time, since they are
  shared across every instance of the `Service` subclass. (M1, v1 plan)
- `Assistant::Service.input_definitions` — per-subclass hash exposing the
  original `input` declaration options (including `:default`) for
  introspection. Experimental; subject to change before 1.0.0.
- `Assistant::Service.input` now accepts `allow_nil: true`. When set,
  any supplied value for that key short-circuits both `valid_type_<name>?`
  and `valid_require_<name>?` — i.e. `nil` is accepted, and type-checking
  is effectively disabled for the input. When `allow_nil:` is omitted
  (default), behaviour is unchanged from 0.1.0 — an absent or `nil` value
  silently passes type checks, and a `nil` on a `required:` input is
  still treated as missing. (M2, v1 plan)
- `Assistant::Service.input` now accepts an array for `type:`, e.g.
  `input :amount, type: [Integer, Float]`. The generated
  `valid_type_<name>?` validator passes when the input matches **any** of
  the listed types. Single-type declarations keep the original
  `"… is not a X but Y"` error message; multi-type produces
  `"… is not one of [A, B] but Y"`. (M3, v1 plan)
- `Assistant::Service#logs` public reader exposing the full log timeline
  (info + warning + error) in insertion order. Callers no longer need to
  reach into `@logs` via `instance_variable_get`. (M4, v1 plan)
- `Assistant::LogList#log_item_info`, `#log_item_warning`, and
  `#log_item_error` shorthands. These wrap `add_log(level: ..., …)` so
  service authors stop hand-rolling the level keyword on every call.
  (M5, v1 plan)
- `Assistant::Service.input` now accepts an `optional:` flag. `optional: true`
  is explicit sugar for the default behaviour (no `required:` validator is
  generated); `optional: false` is equivalent to `required: true`. Declaring
  `required: true` and `optional: true` together raises `ArgumentError` at
  class-definition time, as does a non-boolean `optional:` value. The flag is
  retained in `Service.input_definitions` for introspection and composes with
  `default:` (M1) and `allow_nil:` (M2) without surprises. (M7, v1 plan)

### Changed

- `Assistant::LogItem.new` now raises `ArgumentError` when constructed with
  invalid attributes instead of returning an invalid object. Validation runs at
  the end of initialization and reports every failing attribute in one message
  (level, source, detail, message). The `#valid?` predicate family remains for
  introspection and returns `true` for normally constructed instances.
  `LogList#add_log` now inherits this fail-fast behaviour because it constructs
  `LogItem` internally. (M10, v1 plan)
- `Assistant::InputBuilder` split into per-concern submodules under
  `lib/assistant/input_builder/` (`Registry`, `DefaultOption`,
  `OptionalOption`, `Accessors`, `RequireValidator`, `TypeValidator`,
  `Dsl`). The umbrella `Assistant::InputBuilder` `include`s each
  submodule; the public surface (`Service` extends `Assistant::InputBuilder`)
  is unchanged. The `using Assistant::Refinements::StringBlankness`
  refinement now activates only inside the `Accessors` submodule.
  Tests mirror the lib layout under `test/assistant/input_builder/`.
  Removes the temporary `Metrics/ModuleLength: Max: 150` override from
  `.rubocop.yml`. (M13, v1 plan)
- For each `input :name, required: true` declaration, `Service` subclasses
  now generate `#valid_required_<name>?` as the canonical requirement
  validator (and `#valid_required_conditional_<name>?` when `if:` is also
  given). The pre-existing `#valid_require_<name>?` / `#valid_require_conditional_<name>?`
  predicates remain as deprecated aliases — they delegate to the
  canonical method and emit a `Kernel.warn` once per textual call site
  pointing at the canonical replacement. `Service#validate_inputs`
  invokes only the canonical names, so internal framework code never
  triggers the deprecation warning. See
  [`docs/deprecations.md`](docs/deprecations.md). (M9, v1 plan)
- `lib/assistant.rb` now requires every core building block explicitly in
  dependency order (`version`, `log_item`, `log_list`,
  `refinements/string_blankness`, `input_builder`, `service`). After a bare
  `require "assistant"`, `Assistant::LogList`, `Assistant::InputBuilder`, and
  `Assistant::Refinements::StringBlankness` are reachable without first
  loading `Assistant::Service`. (M6, v1 plan)

### Deprecated

- `Assistant::Service#valid_require_<name>?` (use
  `#valid_required_<name>?` instead). Scheduled for removal in
  `assistant 2.0`. (M9, v1 plan)
- `Assistant::Service#valid_require_conditional_<name>?` (use
  `#valid_required_conditional_<name>?` instead). Scheduled for removal
  in `assistant 2.0`. (M9, v1 plan)

### Migration

`1.0.0` is a stabilisation release. Three small breaking changes have
to be addressed; every one is mechanical and `git grep`-able. The full
recipe lives in
[`docs/v1/06-migration-0x-to-1.md`](docs/v1/06-migration-0x-to-1.md).

1. **`LogList#merge_logs` is keyword-only (M12, B3)** — rewrite every
   `merge_logs(other.logs)` call site to `merge_logs(logs: other.logs)`.
   The two public DSL entry points `Service.input` and `Service.inputs`
   keep their leading positional `attr_name` / `attr_names`; only
   `merge_logs` and the internal `InputBuilder` helpers changed.
2. **`LogItem.new` raises on invalid attrs (M10, B1)** — audit any
   direct `LogItem.new(...)` call sites. The gem's own call sites are
   already correct; fixtures that exercised the old "constructs but
   `valid? == false`" path need updating. Prefer the `add_log` /
   `log_item_*` helpers in regular code.
3. **`valid_require_*?` is deprecated (M9, B2)** — rename direct calls
   to the new `valid_required_*?` form. Users who don't call these
   predicates directly (driven internally by `validate_inputs`) need
   no source change; the old name still works in 1.x with a one-time
   `Kernel.warn` per call site, and is removed in 2.0.

Pin to `~> 1.0` in your `Gemfile` once the upgrade lands.

## [0.1.0] - 2026-05-07

### Added

- `LogList#log_item_error_initialize` helper, used by `InputBuilder`-generated
  validators (previously redefined on every `input` declaration).
- GitHub Actions CI workflow (`.github/workflows/ci.yml`) running Minitest and
  RuboCop.
- GitHub Actions release workflow (`.github/workflows/release.yml`) using
  RubyGems trusted publishing (OIDC) on `v*.*.*` tags.
- Direct test coverage for `LogList#warnings`, `#errors`, `#merge_logs`,
  `Service#success?`, `#failure?`, `#status`, `#result` memoization,
  conditional requirement behavior, the `inputs(...)` plural DSL form, and
  `LogItem#trace`/`#item`.

### Changed

- Standardized on Ruby 3.4 (`.ruby-version`, gemspec `required_ruby_version`,
  RuboCop `TargetRubyVersion`).
- `InputBuilder` no longer requires `active_support`; the previous use of
  `Object#present?` is replaced with plain Ruby checks. Whitespace-only
  strings continue to be treated as missing via a scoped
  `Assistant::Refinements::StringBlankness` refinement that adds
  `String#whitespace?` and is activated inside `InputBuilder`. The method is
  intentionally named to avoid colliding with ActiveSupport's `String#blank?`.
- `assistant.gemspec` `changelog_uri` now points at `CHANGELOG.md` instead of
  `CODE_OF_CONDUCT.md`.
- Migrated the test suite from RSpec to Minitest (`test/**/*_test.rb`),
  exposed via `rake test` (the new default rake task).
- Replaced the largely-dead RuboCop config (a fork of RuboCop's own internal
  config) with a focused configuration for this gem; `rubocop-rspec` is
  replaced with `rubocop-minitest`.

### Removed

- CircleCI configuration (`.circleci/`); replaced by GitHub Actions.
- Dead `@keys = []` instance variable in `Assistant::Service#initialize`.
- `active_support` and `active_support/core_ext/object` requires from
  `lib/assistant/input_builder.rb`.
- RSpec, FactoryBot, Faker, `rspec-collection_matchers`,
  `rspec_junit_formatter`, `rubocop-faker`, and `rubocop-rspec` development
  dependencies; replaced by `minitest` and `rubocop-minitest`.

## [0.0.2] - 2023-11-27

- Initial public release.

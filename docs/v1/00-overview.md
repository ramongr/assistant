<!-- markdownlint-disable MD013 MD024 -->
# 00 — Overview

## Vision

`assistant` is a tiny, dependency-free Ruby library for writing **soft-fail,
composable service objects**. A service declares its inputs, validates them,
optionally runs custom validation, executes its body, and returns a uniform
result that always carries either a value plus warnings or a list of errors —
never raises for expected failures.

The 1.0 release is about **stabilising the existing surface** rather than
expanding it. Anyone using `0.1.0` today should be able to upgrade to `1.0.0`
with at most a small, documented set of code-mods.

## In scope for 1.0

- Freeze the public API documented in [`01-api-surface.md`](./01-api-surface.md).
- Land the "must" feature items in [`02-features.md`](./02-features.md).
- Replace the bundler-template `README.md` and add user guides
  (see [`03-documentation.md`](./03-documentation.md)).
- Populate `lib/assistant/*.rbs` signatures and wire Steep into CI as an
  allowed-failure job.
- Reach ≥95% line coverage and ≥90% branch coverage with SimpleCov in CI.
- Publish `1.0.0` on RubyGems via the existing OIDC trusted-publishing flow
  (`.github/workflows/release.yml`).

## Non-goals for 1.0

- ActiveModel / ActiveRecord coupling or any Rails-specific runtime
  dependency.
- Rails generators or Railtie integration.
- Async or concurrent execution primitives.
- A plug-in marketplace, schema DSL, or pluggable serializer story.
- A documentation site as a **1.0 gate**. A GitHub Pages site built with
  Jekyll + just-the-docs is being assembled as a parallel deliverable tracked
  in [`08-github-pages.md`](./08-github-pages.md); it does not block
  the `v1.0.0` tag and the README links at the in-repo Markdown until
  the site is live.

## Personas and primary use cases

1. **Rails service object author** — wraps a multi-step domain operation;
   wants per-input validation, warnings vs. errors, and a predictable result
   shape that controllers can pattern-match.
2. **CLI command handler** — drives a Thor/Optimist command; wants typed
   inputs, structured logs, and a clean exit code derived from `#status`.
3. **Background job worker** — invoked by Sidekiq/GoodJob; wants idempotent
   execution that never raises on validation problems and exposes a
   machine-readable error list.

## Success criteria

A "v1.0.0" tag may be cut once **all** of the following are true:

- [ ] All "must" items in [`02-features.md`](./02-features.md) are merged.
- [ ] [`01-api-surface.md`](./01-api-surface.md) is marked **Frozen** (no open
      questions in [`07-risks-and-open-questions.md`](./07-risks-and-open-questions.md)
      affecting public API).
- [ ] `README.md` no longer contains any `TODO:` from the bundler template.
- [ ] Every public method has a YARD comment and a corresponding RBS signature.
- [ ] CI is green on Ruby 3.4 and the latest stable Ruby on `main`.
- [ ] `bundle exec rake ci` (test + rubocop + steep) is green
      locally and in CI.
- [ ] SimpleCov reports ≥95% line / ≥90% branch coverage.
- [ ] `CHANGELOG.md` has a complete `[1.0.0]` section with migration notes.
- [ ] A `v1.0.0.rc1` pre-release was published to RubyGems and smoke-tested in
      a fresh Ruby 3.4 project.

## Anti-success criteria (red flags that block 1.0)

- Any breaking change is shipped without a deprecation cycle or a documented
  code-mod in [`06-migration-0x-to-1.md`](./06-migration-0x-to-1.md).
- The gem grows a runtime dependency.
- Any public method exists without a YARD doc or RBS signature.
- Coverage drops below the gates listed above.

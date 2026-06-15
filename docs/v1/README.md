<!-- markdownlint-disable MD013 MD024 -->
# Assistant — v1 Plan

This folder contains the planning documents for the **1.0.0** release of the
[`assistant`](../../README.md) gem. The current shipped version is `0.1.0`
(see `lib/assistant/version.rb:4` and `CHANGELOG.md`). The goal of v1 is to
freeze a small, dependency-free, soft-fail composable services API; ship full
documentation; populate RBS signatures; and publish `1.0.0` to RubyGems via the
existing trusted-publishing workflow.

## How to read these documents

Read them in order on a first pass; cross-reference as needed afterwards.

| #  | File                                                       | Purpose                                                                       |
|----|------------------------------------------------------------|-------------------------------------------------------------------------------|
| 00 | [`00-overview.md`](./00-overview.md)                       | Vision, scope, non-goals, success criteria for 1.0.                           |
| 01 | [`01-api-surface.md`](./01-api-surface.md)                 | Frozen public API, semver contract, deprecation policy, breaking changes.     |
| 02 | [`02-features.md`](./02-features.md)                       | Feature roadmap toward 1.0 (must / should / won't).                           |
| 03 | [`03-documentation.md`](./03-documentation.md)             | README rewrite, user guides, API reference, examples.                         |
| 04 | [`04-release-checklist.md`](./04-release-checklist.md)     | Release engineering: gemspec, changelog, tagging, OIDC publish.               |
| 05 | [`05-quality-and-tooling.md`](./05-quality-and-tooling.md) | Tests, coverage, RuboCop, Brakeman, Fasterer, RBS/Steep, CI matrix.           |
| 06 | [`06-migration-0x-to-1.md`](./06-migration-0x-to-1.md)     | Migration notes for users moving from `0.x` to `1.0`.                         |
| 07 | [`07-risks-and-open-questions.md`](./07-risks-and-open-questions.md) | Decisions still to make before tagging 1.0.                          |
| 08 | [`08-github-pages.md`](./08-github-pages.md)               | GitHub Pages site (mkdocs-material) — parallel track, **not** a 1.0 gate.    |

## Status legend

The same legend is used in every checklist across these documents:

- `[ ]` Planned — not started.
- `[~]` In progress — actively being worked on.
- `[x]` Done — merged on `main`.
- `[-]` Won't do — explicitly deferred or rejected; rationale in the same line.

## Decisions snapshot (Phase 0 reconciliation)

All Q1–Q9 open questions are resolved in
[`07-risks-and-open-questions.md`](./07-risks-and-open-questions.md)'s
Resolution log. Highlights that diverge from the original
recommendations:

- **Q2**: `valid_require_*?` is **deprecated** in 1.0 with `Kernel.warn`,
  removed in 2.0. New canonical name: `valid_required_*?` (M9).
- **Q6**: **RBS is canonical**, YARD is supporting prose. Steep is a
  **required** CI job day one (M8 + M11 + tooling changes).
- **Q8**: `LogItem.new` **raises `ArgumentError`** on invalid attrs
  (breaking change; M10).
- **S1–S4**: all promoted from "Should" to **Must** for 1.0 (callbacks,
  `call_service`, `Assistant.notifier=`, `Service#input_snapshot`).
- **M11**: new bundled `bin/assistant-rbs` CLI generates per-class RBS
  signatures for user `Assistant::Service` subclasses; ships
  **Experimental** in 1.0 and **blocks** 1.0.0.
- **M12**: every public and internal method becomes **keyword-only**
  (breaking) **except** `Service.input` / `Service.inputs`, which keep
  their leading positional name for class-body readability.
  `LogList#merge_logs(other)` becomes `#merge_logs(logs: other)`.
  Mechanical, `git grep`-able; no runtime shim.
- **Coverage**: target raised to ≥98% line / ≥95% branch but enforced as
  a **soft gate** (report only).
- **PR granularity**: one PR per concern (~20 PRs total).
- **RC soak**: no fixed period; tag `v1.0.0` when smoke-test passes.
- **GitHub Pages site**: added as a parallel deliverable under
  [`08-github-pages.md`](./08-github-pages.md) — mkdocs-material, deploys
  via GH Actions. **Does not block the 1.0 tag**; ships incrementally
  across its own ~13 PRs. The README's documentation index will switch
  to the live `https://ramongr.github.io/assistant/` URL once the site
  is up.

## Out of scope for the planning documents

- Actual implementation of features in [`02-features.md`](./02-features.md).
- Writing the user-facing docs described in [`03-documentation.md`](./03-documentation.md).
- Tagging or publishing `1.0.0` (see [`04-release-checklist.md`](./04-release-checklist.md)).

## Top-level cross-references

- Source entry point: `lib/assistant.rb:1`.
- Service base class: `lib/assistant/service.rb:8`.
- Input DSL: `lib/assistant/input_builder.rb:9`.
- Log primitives: `lib/assistant/log_item.rb:5`, `lib/assistant/log_list.rb:5`.
- CI workflow: `.github/workflows/ci.yml`.
- Release workflow: `.github/workflows/release.yml`.

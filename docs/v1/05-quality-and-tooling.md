<!-- markdownlint-disable MD013 MD024 -->
# 05 — Quality and Tooling

## Test suite

Today the suite is Minitest under `test/` (per the 0.1.0 migration noted in
`CHANGELOG.md:38`) and includes:

- `test/assistant_test.rb`
- `test/assistant/service_test.rb`
- `test/assistant/input_builder_test.rb`
- `test/assistant/log_item_test.rb`
- `test/assistant/log_list_test.rb`
- `test/test_helper.rb`

### Goals for 1.0

- [x] Add SimpleCov to the dev dependencies and require it from
      `test/test_helper.rb` before `require "assistant"`.
- [x] Configure SimpleCov:
  - Track lines and branches.
  - **Target** (soft gate; report only): line ≥98%, branch ≥95%. CI
    surfaces the numbers in the job summary but does **not** fail when
    below target. Human review enforces the gate per the
    [`07-risks-and-open-questions.md`](./07-risks-and-open-questions.md)
    decision.
  - Output to `coverage/`; gitignore the directory.
- [x] Add a CI step that publishes the SimpleCov HTML as an artifact for
      easy inspection on PRs.
- [x] Add a CI step that prints line/branch percentages to the GitHub
      Actions job summary (`$GITHUB_STEP_SUMMARY`).
- [ ] Add `test/docs/` for example-block tests required by
      [`03-documentation.md`](./03-documentation.md) D5 acceptance criteria.

## RuboCop

Configuration lives in `.rubocop.yml` and `.rubocop_todo.yml`.

- [x] Confirm `TargetRubyVersion: 3.4` matches the gemspec
      (`assistant.gemspec:20`) and CI floor. All three are aligned:
      `.rubocop.yml` sets `TargetRubyVersion: 3.4`, the gemspec sets
      `required_ruby_version = '>= 3.4'`, and the CI matrix floor in
      `.github/workflows/ci.yml` is `'3.4'`.
- [x] Inspect `.rubocop_todo.yml` and either fix or explicitly re-disable
      every offense; aim for an empty TODO at 1.0.0. The TODO file held
      zero overrides (only the autogen header from RuboCop 1.57.2 in
      2023); deleted in this change, and the corresponding
      `inherit_from:` directive was removed from `.rubocop.yml`.
      `bundle exec rubocop` stays clean on 40 files.
- [ ] Keep the existing `rubocop-minitest`, `rubocop-performance`,
      `rubocop-rake` extensions (per `Gemfile.lock`).
- [x] Adopt `rubocop-style-compact_nesting` (added with M13). Enforces
      a hybrid nesting style across `lib/` and `test/`: namespace chains
      collapse to a single `module A::B::C` line; when the innermost
      definition is a class, that class is nested separately inside the
      compact module wrapper. The plugin disables
      `Style/ClassAndModuleChildren` automatically. Namespace shells for
      `Assistant::InputBuilder` and `Assistant::Refinements` are
      predeclared in `lib/assistant.rb` so multi-segment files load
      without ordering hazards.
- [x] Drop the temporary `Metrics/ModuleLength: Max: 150` override
      (added for M7) once M13 ships and `lib/assistant/input_builder.rb`
      is split into per-concern submodules. See
      [`02-features.md`](./02-features.md) M13. Removed alongside M13
      (PR #143, `01d82b1`); `.rubocop.yml` now has no `Metrics/ModuleLength`
      override.

## Static analysis (Brakeman / Fasterer)

Both gems were considered as additional CI checks during planning. Both were
**dropped for 1.0** after empirical evaluation; the dev dependencies were
removed alongside this decision.

- [x] Brakeman — **not planned for 1.0.** Brakeman is a Rails-specific
      static analyzer (controllers / models / templates / SQL sinks). The
      gem has no Rails surface, so Brakeman refuses to run without
      `--force` and, with `--force`, reports `0 warnings` because there is
      nothing for it to inspect. Re-evaluate if the gem ever grows a Rails
      integration. Dev dep removed (was `brakeman ~> 8.0`).
- [x] Fasterer — **not planned for 1.0.** Fasterer surfaces micro-optimisation
      hints that overlap with `rubocop-performance` (already enabled) and
      tends toward noise on a small, well-typed surface. Re-evaluate if a
      hot path shows up in benchmarking. Never added to dev deps.
- [x] Wire a new `rake ci` aggregate task so contributors get a one-shot
      local equivalent of CI. Implemented in `Rakefile`; runs
      `test` → `rubocop` → `steep`.

### `Rakefile` aggregate (shipped)

The Rakefile defines a `ci` task that mirrors the individual CI jobs:

```ruby
# Rakefile (excerpt)
begin
  require 'rubocop/rake_task'
  RuboCop::RakeTask.new
rescue LoadError
  # rubocop is a development-only dependency
end

desc 'Run Steep type-check (matches the required CI job)'
task :steep do
  sh 'bundle exec steep check --jobs=1'
end

desc 'Run the full local CI pipeline: test + rubocop + steep'
task ci: %i[test rubocop steep]
```

CI keeps the per-tool jobs (`test`, `rubocop`, `steep`, `coverage`) for
faster feedback and parallel execution; `rake ci` is the contributor-facing
local equivalent. See `Rakefile` and [`ci.yml`](../../.github/workflows/ci.yml).

## RBS / Steep

Today `lib/assistant/service.rbs` is an empty class declaration
(`lib/assistant/service.rbs:3`). Q6 was decided in favour of
**RBS canonical, Steep required day one**. For 1.0:

- [ ] Implement `lib/assistant/service.rbs` matching the Frozen surface in
      [`01-api-surface.md`](./01-api-surface.md).
- [ ] Add `lib/assistant/log_item.rbs`, `log_list.rbs`,
      `input_builder.rbs`, and `version.rbs`.
- [ ] Add `Steepfile` at the repo root with a `target :lib` that targets
      `lib/**/*.rb` and uses the local `sig/` (or in-file `.rbs` siblings).
- [ ] Add `steep` as a dev dependency.
- [ ] Add a **required** CI job `steep check`. The per-class generated
      output from M11 is exercised via a fixture under `test/fixtures/`
      with a Steep target that must stay green.
- [ ] Document the limitation that `Service.input(:foo, ...)`-generated
      methods cannot be expressed precisely in RBS by hand on the gem
      side; users generate per-class sigs with `bin/assistant-rbs` (M11).
      Surface this in `docs/guides/inputs.md` per D2 in
      [`03-documentation.md`](./03-documentation.md).

## CI matrix

Current matrix (`.github/workflows/ci.yml:21`): `['3.4', '4.0']`.

- [ ] Keep the floating `'4.0'` entry (Q5 decision: Ruby 4.0 has shipped
      stable; `ruby/setup-ruby` resolves to the latest 4.0.x). Floor
      stays at `'3.4'`.
- [ ] Keep `fail-fast: false` so a single Ruby's flake doesn't mask others.
- [ ] Run RuboCop on the highest matrix entry only (current behaviour;
      `.github/workflows/ci.yml:38`).
- [x] Add a `coverage` job that runs the test suite once with SimpleCov and
      uploads the artifact (soft gate).
- [x] Add a **required** `steep` job per the section above. Already
      live in `.github/workflows/ci.yml`; required by branch protection
      via the `Steep` check.

## Bundler / dependency hygiene

- [ ] Keep `bundler ~> 4.0` as a dev dep (`assistant.gemspec:37`).
- [x] Keep zero runtime gem dependencies; add a CI assertion that
      `Gem::Specification.load("assistant.gemspec").runtime_dependencies` is
      empty. New `runtime-deps` job in `.github/workflows/ci.yml` runs the
      one-liner on every push/PR and fails loudly if a runtime dep is ever
      introduced.
- [ ] Re-run `bundle update` and ensure `Gemfile.lock` checksums stay
      reproducible (already enabled via `CHECKSUMS:` block in
      `Gemfile.lock`).
- [ ] Confirm `dependabot.yml` (`.github/dependabot.yml`) covers `bundler`
      and `github-actions` weekly.

## `bin/` scripts

- [ ] Smoke-test `bin/setup`, `bin/console`, `bin/version` on a clean
      checkout. Document them in `CONTRIBUTING.md` (D4 in
      [`03-documentation.md`](./03-documentation.md)).

## Acceptance criteria

- [x] `bundle exec rake ci` exits 0 locally (test + rubocop + steep).
      CI exercises each tool in a dedicated job for parallelism.
- [ ] Coverage reported (soft gate; ≥98% line / ≥95% branch is the
      target but not enforced in CI).
- [ ] No new runtime dependencies have been introduced.
- [ ] Required Steep CI job is green on `main` and on every PR.

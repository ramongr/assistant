<!-- markdownlint-disable MD043 -->
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

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

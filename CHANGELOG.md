<!-- markdownlint-disable MD043 -->
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

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
- `lib/assistant.rb` now requires every core building block explicitly in
  dependency order (`version`, `log_item`, `log_list`,
  `refinements/string_blankness`, `input_builder`, `service`). After a bare
  `require "assistant"`, `Assistant::LogList`, `Assistant::InputBuilder`, and
  `Assistant::Refinements::StringBlankness` are reachable without first
  loading `Assistant::Service`. (M6, v1 plan)

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

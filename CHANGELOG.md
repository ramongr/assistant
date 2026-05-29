<!-- markdownlint-disable MD043 -->
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

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

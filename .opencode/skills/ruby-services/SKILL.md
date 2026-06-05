---
name: ruby-services
description: Use when creating, changing, testing, or reviewing Ruby service objects, especially Assistant::Service subclasses, service inputs, validation, execution, logs, or Minitest coverage.
---

# Ruby Services

Use this skill when working on Ruby service objects in this repository,
especially `Assistant::Service` subclasses or framework behavior that affects
service inputs, validation, execution, logs, result hashes, or tests.

Do not use this skill for unrelated Ruby scripts, packaging-only changes, or
opencode configuration tasks unless the work directly concerns Ruby service
guidance.

## Core Approach

- Preserve the existing `Assistant::Service` public API unless the user asks for
  an API change.
- Prefer soft-fail service behavior: report domain and validation failures with
  error logs instead of raising, unless an exception is explicitly part of the
  API being changed.
- Keep service logic clear and object-oriented: every method should have one
  responsibility.
- Only add a private helper when it makes sense in the context of the service's
  domain and improves readability.
- Keep helper names aligned with what the service does, not generic process
  steps like `handle_data` or `process_stuff`.
- Do not add arguments to service instance methods other than `initialize`.
  Service behavior should use declared inputs and instance state.
- Return computed data from `execute`; put pre-execution domain checks in
  `validate`.
- Use `log_item_warning`, `log_item_error`, `log_item_info`, or
  `add_log(level:, source:, detail:, message:)` consistently with existing
  log patterns.

## Inputs

- Declare service inputs with `input name: :name, type: SomeClass` and existing DSL
  options such as `required:`, `optional:`, `default:`, `allow_nil:`, and `if:`.
- Prefer `default: -> { [] }` or `default: -> { {} }` for mutable defaults.
- Use `allow_nil: true` only when explicit `nil` is a valid service value.
- Do not depend on deprecated `valid_require_*?` names in new internal code;
  use the canonical `valid_required_*?` names.

## Tests

- Add or update Minitest coverage under `test/**/*_test.rb` for behavior
  changes.
- Use anonymous `Class.new(Assistant::Service)` fixtures for framework-level
  service behavior, matching the existing tests.
- Assert the service result hash shape, `status`, `warnings`, `errors`, logs,
  and memoization when relevant.
- For input DSL changes, cover required, optional, default, type, conditional,
  and `allow_nil` behavior as applicable.
- Use helpers from `test/test_helper.rb` for log-item construction or warning
  capture instead of duplicating helper setup.

## Style

- Ruby target is 3.4.
- Start Ruby files with `# frozen_string_literal: true`.
- Prefer concise Ruby that matches nearby code; endless methods are acceptable
  where they are already used.
- Respect the repo's hybrid compact nesting convention from
  `rubocop-style-compact_nesting`.
- Keep public API documentation aligned with `docs/v1/01-api-surface.md` and
  user-facing changes aligned with `CHANGELOG.md` when appropriate.
- Make the smallest correct change; avoid generic abstractions until there is a
  concrete second use.

## Verification

Run the focused test first when possible, then the broader checks relevant to
the change:

```sh
bundle exec ruby -Itest test/assistant/service_test.rb
bundle exec rake test
bundle exec rubocop
```

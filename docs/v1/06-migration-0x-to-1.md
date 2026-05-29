<!-- markdownlint-disable MD013 MD024 -->
# 06 — Migrating from 0.x to 1.0

This document is the user-facing migration story. It is intentionally short
because 1.0 is a **stabilisation** release: most users will upgrade with no
code changes.

## TL;DR

If your app does **all** of the following, you can upgrade by bumping the
constraint in your `Gemfile` to `gem 'assistant', '~> 1.0'`:

- You only call `Service.run(...)` and read `:result`, `:status`,
  `:warnings`, `:errors` from the returned hash.
- You declare inputs with `input :name, type: T` and optionally
  `required: true` and/or `if: ->(v) { ... }`.
- You override `#execute` and (optionally) `#validate`.
- You log via `add_log(level:, source:, detail:, message:)` with valid
  attributes (see breaking-change note below).
- You inspect logs via `infos`, `warnings`, `errors` (the `LogList` mixin).

## Breaking changes (read first)

Two behavioural changes ship in 1.0 that may require code changes:

### B1. `Assistant::LogItem.new` raises on invalid construction

- **Before** (0.1.0): `LogItem.new(level: '', ...)` succeeded and
  `#valid?` returned `false`.
- **After** (1.0.0): the same call raises `ArgumentError` with a message
  listing every failing attribute.
- **Migration**:
  - Audit every direct `LogItem.new` call to confirm the four required
    attrs (`level`, `source`, `detail`, `message`) are non-empty and
    `level` is one of `:info`, `:warning`, `:error`.
  - Audit every `add_log(level:, source:, detail:, message:)` call for
    the same; `add_log` constructs a `LogItem` internally.
  - The `#valid?` family of predicates is **retained** for backwards
    compatibility (e.g. for code that introspects logs after the fact).
    In normal flows they always return `true` post-construction.
- See M10 in [`02-features.md`](./02-features.md).

### B2. `valid_require_*?` predicate deprecation

- **Before** (0.1.0): the DSL generated `#valid_require_<name>?` and
  `#valid_require_conditional_<name>?` predicates for `required: true`
  inputs.
- **After** (1.0.0): the canonical names are `#valid_required_<name>?`
  and `#valid_required_conditional_<name>?`. The old names remain as
  aliases for one minor (`1.x`) but emit a one-time-per-call-site
  `Kernel.warn`:
  ```text
  assistant: `#valid_require_email?` is deprecated; use `#valid_required_email?` (removed in assistant 2.0)
  ```
- **Migration**: rename direct calls in your own code. Most users don't
  call these predicates directly (they're driven by `validate_inputs`
  inside the gem); no action is required for those users.
- See M9 in [`02-features.md`](./02-features.md) and the entry in
  `docs/deprecations.md`.

### Recipe: `bin/assistant-rbs` for Steep users

If you use Steep against your services, run the new bundled CLI to
generate per-class signatures (the gem-side RBS cannot express
metaprogrammed per-input getters):

```sh
bundle exec assistant-rbs app/services/ --output sig/services
bundle exec steep check
```

The generator is **Experimental** in 1.0; the output format may evolve in
1.x with a deprecation cycle.

## Per-symbol diff (0.1.0 → 1.0.0)

| Symbol                                          | 0.1.0                                                | 1.0.0                                                                                  | Action required                                |
|-------------------------------------------------|------------------------------------------------------|----------------------------------------------------------------------------------------|------------------------------------------------|
| `Assistant::VERSION`                            | `'0.1.0'` (`lib/assistant/version.rb:4`)             | `'1.0.0'`                                                                              | None.                                          |
| `Service.input`                                 | `name`, `type:`, `required:`, `if:`                   | adds `default:` (M1), `allow_nil:` (M2), `type:` accepts an array (M3), `optional:` (M7) | None (back-compat additive).                   |
| `Service.inputs`                                | unchanged                                            | unchanged                                                                              | None.                                          |
| `Service#run` result hash                       | `{ result:, status:, warnings: }` / `{ errors:, result: nil, status: :with_errors }` | unchanged                                                          | None.                                          |
| `Service#status` enum                           | `:ok`, `:with_warnings`, `:with_errors`              | unchanged                                                                              | None.                                          |
| `Service#logs`                                  | not exposed; `instance_variable_get(:@logs)` only    | `attr_reader :logs` (M4)                                                               | Optional: replace any IVar peeks with `#logs`. |
| `LogList#log_item_warning` / `_info` / `_error` | did not exist                                        | added (M5)                                                                             | Optional: simplify call sites.                 |
| `String#whitespace?`                            | refinement scoped to `InputBuilder`                  | unchanged, still internal                                                              | Do not `using` it directly.                    |
| `LogItem.new` on invalid attrs                  | succeeded; `valid? == false`                         | **raises `ArgumentError`** (M10)                                                       | See B1 above.                                  |
| `valid_require_*?` predicate naming             | only name available                                  | aliased to `valid_required_*?`; old name **deprecated**, removed in 2.0 (M9)           | See B2 above.                                  |
| `Service.before_/after_/around_execute`         | did not exist                                        | added (M-S1)                                                                           | Opt-in; no migration.                          |
| `Service#call_service`                          | did not exist                                        | added (M-S2)                                                                           | Optional: replace manual `inner.run` + log merge. |
| `Assistant.notifier=`                           | did not exist                                        | added (M-S3)                                                                           | Opt-in.                                        |
| `Service#input_snapshot`                        | did not exist                                        | added (M-S4)                                                                           | Opt-in.                                        |
| `bin/assistant-rbs` CLI                         | did not exist                                        | added (M11, Experimental)                                                              | Opt-in for Steep users.                        |
| `lib/assistant/service.rbs`                     | empty class declaration                              | populated, Steep required in gem CI                                                    | If you ran Steep against 0.1.0, re-run; the new sig is more accurate. Use `bin/assistant-rbs` for your own services. |

## What you might want to clean up after upgrading

These are not required but become simpler with 1.0:

1. Replace direct `@logs` access with `#logs`:

   ```ruby
   # before
   service.send(:instance_variable_get, :@logs)

   # after
   service.logs
   ```

2. Replace verbose `add_log(level: :warning, ...)` calls with the
   shorthand:

   ```ruby
   # before
   add_log(level: :warning, source: :execute, detail: :rate_limited, message: 'slow down')

   # after
   log_item_warning(source: :execute, detail: :rate_limited, message: 'slow down')
   ```

3. Replace explicit defaulting with the `default:` option:

   ```ruby
   # before
   input :limit, type: Integer
   def limit
     @inputs[:limit] || 25
   end

   # after
   input :limit, type: Integer, default: 25
   ```

4. Replace explicit `nil`-tolerance with `allow_nil:`:

   ```ruby
   # before
   input :note, type: String
   def execute
     return unless note   # avoid running on nil
     # ...
   end

   # after
   input :note, type: String, allow_nil: true
   ```

5. Replace one-of type guards with multi-type:

   ```ruby
   # before
   input :amount, type: Numeric

   # after — narrower, more explicit
   input :amount, type: [Integer, Float]
   ```

## What was **not** changed in 1.0

- The result hash shape (still a `Hash`, not a `Data` value object). This is
  a deliberate deferral; see [`07-risks-and-open-questions.md`](./07-risks-and-open-questions.md).
- The `if:` predicate semantics (still evaluated only at validate-time).
- The `inputs(...)` plural form (still flat; no per-name overrides).

## Support window

- `0.x` is end-of-life on the `1.0.0` release date.
- `1.0.x` receives security and bug-fix patches for at least 12 months from
  release.
- See `SECURITY.md` (created per [`03-documentation.md`](./03-documentation.md))
  for the canonical, dated supported-versions table.

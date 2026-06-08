<!-- markdownlint-disable MD013 MD024 -->
# 06 — Migrating from 0.x to 1.0

This document is the user-facing migration story. 1.0 is a
**stabilisation** release, but it ships three small breaking changes
that every user has to address (see B1, B2, B3 below). Each of the
three is mechanical and `git grep`-able.

## TL;DR

Bump the constraint in your `Gemfile` to `gem 'assistant', '~> 1.0'`,
then run the following three mechanical rewrites across your code:

1. **`LogList#merge_logs` is keyword-only (B3, M12)**: rewrite every
   `merge_logs(other.logs)` to `merge_logs(logs: other.logs)`.
   `Service.input` / `Service.inputs` are unchanged.
2. **`LogItem.new` raises on invalid attrs (B1, M10)**: audit any
   direct `LogItem.new(...)` call sites you have; the gem's own call
   sites are already correct. Test fixtures that exercised the old
   "constructs but `valid? == false`" path need updating.
3. **`valid_require_*?` is deprecated (B2, M9)**: rename direct calls
   to the new `valid_required_*?` form. Most users do not call these
   predicates directly (they're driven internally by `validate_inputs`)
   so no action is required for those users; the old name still works
   in 1.x with a one-time `Kernel.warn` per call site.

If your app does **all** of the following after those rewrites, no
further changes are needed:

- You only call `Service.run(...)` and read `:result`, `:status`,
  `:warnings`, `:errors` from the returned hash.
- You declare inputs with `input :foo, type: T` and optionally
  `required: true` and/or `if: ->(v) { ... }`.
- You override `#execute` and (optionally) `#validate`.
- You log via `add_log(level:, source:, detail:, message:)` with valid
  attributes.
- You inspect logs via `infos`, `warnings`, `errors` (the `LogList` mixin).

## Breaking changes (read first)

Two behavioural changes ship in 1.0 that may require code changes:

### B1. `Assistant::LogItem.new` raises on invalid construction

- **Before** (0.1.0): `LogItem.new(level: '', ...)` succeeded and
  `#valid?` returned `false`.
- **After** (1.0.0): the same call raises `ArgumentError` with a message
  listing every failing attribute:
  ```text
  invalid LogItem: level must be one of [info, warning, error]; source must be present and different from detail
  ```
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

### B3. `LogList#merge_logs` and internal helpers are keyword-only

- **Before** (0.1.0): `LogList#merge_logs` and every internal
  `Assistant::InputBuilder` helper took their leading name / list
  argument positionally:
  ```ruby
  log_list.merge_logs(other.logs)
  ```
- **After** (1.0.0): `merge_logs` takes `logs:`. The headline DSL
  entry points `Service.input` and `Service.inputs` are
  **deliberately exempt** from M12 — `input :foo, type: X` reads
  better as a class-body declaration than `input name: :foo, type: X`,
  so their leading positional name stays:
  ```ruby
  input :role,        type: String, required: true   # unchanged
  inputs %i[a b c],   type: Integer                  # unchanged
  log_list.merge_logs(logs: other.logs)              # was: merge_logs(other.logs)
  ```
- **Affected signatures**:
  - `Service.input(attr_name, type:, **)` — **unchanged** (exempt).
  - `Service.inputs(attr_names, type:, **)` — **unchanged** (exempt).
  - `LogList#merge_logs(other_logs)` →
    `LogList#merge_logs(logs:)`.
  - All `InputBuilder` helpers
    (`input_getter_meth`, `input_checker_meth`,
    `input_type_validator_meth`, `input_require_validator_meth`,
    `input_require_conditional_meth`, `type_validator_body`,
    `type_mismatch_message_builder`, and the M13-split
    `process_default_option`, `validate_default!`,
    `warn_on_mutable_default`, `process_optional_option`,
    `validate_optional!`, `register_input_definition`) take their
    first argument as `name:` (or `names:`/`types:` where
    appropriate). These are documented as internal but are
    technically public on the class.
  - `LogItem#initialize`, `LogList#add_log`,
    `LogList#log_item_error_initialize`, `LogList#log_item_*`
    shorthands, `Service.run`, and `Service#initialize` were already
    keyword-only in 0.1.0 and are unchanged.
- **Migration**: hard break, no runtime shim. For most users this is
  a single rewrite in any code that composes log lists across
  services (e.g. an outer service merging an inner service's logs
  without going through `Service#call_service`, which handles the
  keyword for you):
  ```sh
  # Anywhere you compose log lists:
  #   foo.merge_logs(bar.logs)  ->  foo.merge_logs(logs: bar.logs)
  ```
  The old positional form raises `ArgumentError: ... required
  keyword: logs` immediately on first call, so every miss is caught
  loudly — there are no silent runtime regressions.
- **Rationale**: see M12 in [`02-features.md`](./02-features.md). The
  internal helpers go keyword-only so that the RBS surface stays
  consistent and so new options can be added without shuffling a
  positional slot. The two public DSL entry points
  (`Service.input` / `Service.inputs`) keep their positional name
  because in a class body the name is the natural subject of the
  declaration and `input :foo, …` reads better than
  `input name: :foo, …`.

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
| `Service.input`                                 | `name`, `type:`, `required:`, `if:`                   | adds `default:` (M1), `allow_nil:` (M2), `type:` accepts an array (M3), `optional:` (M7); leading `attr_name` stays **positional** (exempt from M12) | None — `input :foo, type: X` keeps working. |
| `Service.inputs`                                | `names`, `type:`, `**options`                        | leading `attr_names` stays **positional** (exempt from M12)                            | None — `inputs %i[a b], type: X` keeps working. |
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
| `LogList#merge_logs`                            | `merge_logs(other_logs)` positional                  | `merge_logs(logs:)` keyword-only (M12)                                                 | **Required**: `merge_logs(other.logs)` → `merge_logs(logs: other.logs)`. See B3. |
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

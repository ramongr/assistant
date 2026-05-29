<!-- markdownlint-disable MD013 MD024 -->
# 06 — Migrating from 0.x to 1.0

This document is the user-facing migration story. 1.0 is a
**stabilisation** release, but it ships three small breaking changes
that every user has to address (see B1, B2, B3 below). Each of the
three is mechanical and `git grep`-able.

## TL;DR

Bump the constraint in your `Gemfile` to `gem 'assistant', '~> 1.0'`,
then run the following three mechanical rewrites across your code:

1. **Inputs are keyword-only (B3, M12)**: rewrite every
   `input :foo, type: X` to `input name: :foo, type: X`, every
   `inputs %i[a b], type: X` to `inputs names: %i[a b], type: X`,
   and every `merge_logs(other.logs)` to
   `merge_logs(logs: other.logs)`.
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
- You declare inputs with `input name: :foo, type: T` and optionally
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

### B3. Keyword-only method signatures across the gem

- **Before** (0.1.0): the DSL took the attribute name as a positional
  argument, while every option was a keyword:
  ```ruby
  input  :role,        type: String, required: true
  inputs %i[a b c],    type: Integer
  log_list.merge_logs(other.logs)
  ```
- **After** (1.0.0): every public and internal method is keyword-only.
  The attribute name is now passed as `name:` / `names:`, and
  `LogList#merge_logs` takes `logs:`:
  ```ruby
  input  name:  :role,        type: String, required: true
  inputs names: %i[a b c],    type: Integer
  log_list.merge_logs(logs: other.logs)
  ```
- **Affected signatures**:
  - `Service.input(attr_name, type:, **)` →
    `Service.input(name:, type:, **)`.
  - `Service.inputs(attr_names, type:, **)` →
    `Service.inputs(names:, type:, **)`.
  - `LogList#merge_logs(other_logs)` →
    `LogList#merge_logs(logs:)`.
  - All `InputBuilder` helpers
    (`input_getter_meth`, `input_checker_meth`,
    `input_type_validator_meth`, `input_require_validator_meth`,
    `input_require_conditional_meth`, `type_validator_body`,
    `type_mismatch_message_builder`) take their first argument as
    `name:` (or `names:`/`types:` where appropriate). These are
    documented as internal but are technically public on the class.
  - `LogItem#initialize`, `LogList#add_log`,
    `LogList#log_item_error_initialize`, `LogList#log_item_*`
    shorthands, `Service.run`, and `Service#initialize` were already
    keyword-only in 0.1.0 and are unchanged.
- **Migration**: hard break, no runtime shim. The change is purely
  mechanical and `git grep`-able. Recipe:
  ```sh
  # In each of your service files, rewrite:
  #   input :foo, ...      ->  input name: :foo, ...
  #   inputs %i[a b], ...  ->  inputs names: %i[a b], ...
  #
  # And anywhere you compose log lists:
  #   foo.merge_logs(bar.logs)  ->  foo.merge_logs(logs: bar.logs)
  ```
  The old positional form raises `ArgumentError: missing keyword: :name`
  immediately at class-definition time, so every miss is caught on the
  first load — there are no silent runtime regressions.
- **Rationale**: see M12 in [`02-features.md`](./02-features.md). Mixed
  positional + keyword signatures complicate the RBS surface and the
  M11 RBS generator template; pure-keyword signatures also leave room
  to add further options to `input` without shuffling the positional
  slot.

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
| `Service.input`                                 | `name`, `type:`, `required:`, `if:`                   | `name:` is now a **keyword** (M12); adds `default:` (M1), `allow_nil:` (M2), `type:` accepts an array (M3), `optional:` (M7) | **Required**: `input :foo, type: X` → `input name: :foo, type: X`. See B3. |
| `Service.inputs`                                | `names`, `type:`, `**options`                        | `names:` is now a **keyword** (M12)                                                    | **Required**: `inputs %i[a b], type: X` → `inputs names: %i[a b], type: X`. See B3. |
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

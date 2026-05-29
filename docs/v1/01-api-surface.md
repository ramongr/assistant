<!-- markdownlint-disable MD013 MD024 -->
# 01 — API Surface for 1.0

This document enumerates **every** public symbol that ships in `assistant`
1.0.0, with its signature, stability label, and the file/line where it lives
today. Any symbol not listed here is considered **internal** and may change
without a major version bump.

## Stability labels

- **Frozen** — covered by semver from 1.0.0 onward. Breaking changes require a
  2.0.
- **Experimental** — public but subject to change in a 1.x minor with a
  deprecation cycle.
- **Internal** — not part of the contract; do not rely on it.

## `Assistant` (module)

Defined in `lib/assistant.rb:8`. The module is primarily a namespace; in 1.0
it also exposes a single configuration accessor for the instrumentation hook
(S3).

| Symbol                          | Stability | Notes                                                 |
|---------------------------------|-----------|-------------------------------------------------------|
| `Assistant::VERSION`            | Frozen    | String, follows semver. `lib/assistant/version.rb:4`. |
| `Assistant.notifier`            | Frozen *(new in 1.0)* | Reader for the configured instrumentation proc. Default: no-op proc. See S3 in [`02-features.md`](./02-features.md). |
| `Assistant.notifier=(callable)` | Frozen *(new in 1.0)* | Writer. Accepts any object responding to `#call(event, payload)`. |

## `Assistant::Service`

Defined in `lib/assistant/service.rb:8`.

### Class-level

| Signature                                          | Stability | Source                              |
|----------------------------------------------------|-----------|-------------------------------------|
| `Service.run(**inputs) -> Hash`                    | Frozen    | `lib/assistant/service.rb:14`       |
| `Service.input(name, type:, required: false, if: nil, default: nil, allow_nil: false)` | Frozen | `lib/assistant/input_builder.rb:20` |
| `Service.inputs(names, type:, **options)`          | Frozen    | `lib/assistant/input_builder.rb:13` |

> The `default:` and `allow_nil:` keys are **new in 1.0** — see
> [`02-features.md`](./02-features.md).

### Instance-level

| Signature                                | Stability   | Source                              |
|------------------------------------------|-------------|-------------------------------------|
| `#initialize(**inputs)`                  | Frozen      | `lib/assistant/service.rb:19`       |
| `#run -> Hash`                           | Frozen      | `lib/assistant/service.rb:24`       |
| `#result -> Object` (memoized)           | Frozen      | `lib/assistant/service.rb:35`       |
| `#success? -> Boolean`                   | Frozen      | `lib/assistant/service.rb:39`       |
| `#failure? -> Boolean`                   | Frozen      | `lib/assistant/service.rb:43`       |
| `#status -> :ok / :with_warnings / :with_errors` | Frozen | `lib/assistant/service.rb:47`       |
| `#logs -> Array<Assistant::LogItem>`     | Frozen *(new in 1.0)* | new public reader for `@logs`     |
| `#infos / #warnings / #errors`           | Frozen      | via `LogList` (see below)           |
| `#execute -> Object` (override)          | Frozen      | `lib/assistant/service.rb:61`       |
| `#validate -> void` (override)           | Frozen      | `lib/assistant/service.rb:63`       |

### Generated per-input methods

For every `input :name, type: T` declaration, the following are generated and
considered **Frozen** for 1.0:

- `#name` — getter (`lib/assistant/input_builder.rb:31`).
- `#name?` — present-and-truthy predicate, with whitespace-only strings
  treated as missing (`lib/assistant/input_builder.rb:37`).
- `#valid_type_name?` — `lib/assistant/input_builder.rb:71`.
- `#valid_required_name?` — generated only when `required: true`
  (new canonical name in 1.0). Aliases `#valid_require_name?` for back-compat.
- `#valid_require_name?` — **Deprecated in 1.0**, removed in 2.0. Calls
  emit a one-time `Kernel.warn` per call site (see M9 in
  [`02-features.md`](./02-features.md) and `docs/deprecations.md`).
- `#valid_required_conditional_name?` — generated only when
  `required: true` **and** `if:` is supplied (new canonical name in 1.0).
- `#valid_require_conditional_name?` — **Deprecated in 1.0**, removed in
  2.0.

> Q2 in [`07-risks-and-open-questions.md`](./07-risks-and-open-questions.md)
> was decided in favour of **Option B**: alias + deprecate.

### Result shape

`Service#run` returns one of two hash shapes; both are **Frozen** for 1.0:

```ruby
# Success (status is :ok or :with_warnings)
{ result: <Object>, status: :ok | :with_warnings, warnings: Array<LogItem> }

# Failure (any error logged before or during validation)
{ errors: Array<LogItem>, result: nil, status: :with_errors }
```

Status values are exhaustively `:ok`, `:with_warnings`, `:with_errors`. No new
status values may be introduced in 1.x without a deprecation cycle.

## `Assistant::LogItem`

Defined in `lib/assistant/log_item.rb:5`.

> **Breaking change in 1.0**: `LogItem.new` now raises `ArgumentError`
> when any required attribute is invalid (previously, construction always
> succeeded and `#valid?` returned `false`). The `#valid?` family of
> predicates is **retained** for introspection; in normal flows they
> always return `true` after construction. Q8 in
> [`07-risks-and-open-questions.md`](./07-risks-and-open-questions.md)
> was decided in favour of the strict semantics; tracked as M10 in
> [`02-features.md`](./02-features.md).

| Signature                                                                | Stability | Source                          |
|--------------------------------------------------------------------------|-----------|---------------------------------|
| `LogItem.new(level:, source:, detail:, message:, trace: nil)`            | Frozen *(raises in 1.0)* | `lib/assistant/log_item.rb:10`  |
| `#level / #source / #detail / #message / #trace`                         | Frozen    | `lib/assistant/log_item.rb:8`   |
| `#info? / #warning? / #error?`                                           | Frozen    | `lib/assistant/log_item.rb:26`  |
| `#valid? / #valid_level? / #valid_source? / #valid_detail? / #valid_message?` | Frozen | `lib/assistant/log_item.rb:18`  |
| `#item -> Hash`                                                          | Frozen    | `lib/assistant/log_item.rb:22`  |
| `LogItem::VALID_LEVELS` constant `%i[info warning error]`                | Frozen    | `lib/assistant/log_item.rb:6`   |

## `Assistant::LogList` (mixin)

Defined in `lib/assistant/log_list.rb:5`. Mixed into `Assistant::Service`.

| Signature                                              | Stability | Source                              |
|--------------------------------------------------------|-----------|-------------------------------------|
| `#add_log(level:, source:, detail:, message:, trace: nil)` | Frozen | `lib/assistant/log_list.rb:6`       |
| `#merge_logs(other_logs)`                              | Frozen    | `lib/assistant/log_list.rb:10`      |
| `#log_item_error_initialize(attr_name:, message:)`     | Frozen    | `lib/assistant/log_list.rb:16`      |
| `#log_item_info(source:, detail:, message:, trace: nil)`    | Frozen *(new in 1.0)* | M5 in [`02-features.md`](./02-features.md) |
| `#log_item_warning(source:, detail:, message:, trace: nil)` | Frozen *(new in 1.0)* | M5 in [`02-features.md`](./02-features.md) |
| `#log_item_error(source:, detail:, message:, trace: nil)`   | Frozen *(new in 1.0)* | M5 in [`02-features.md`](./02-features.md) |
| `#infos / #warnings / #errors`                         | Frozen    | `lib/assistant/log_list.rb:20`      |

## `Assistant::InputBuilder` (mixin)

Defined in `lib/assistant/input_builder.rb:9`. **Internal**: it is extended
into `Assistant::Service`'s singleton; users are expected to call `.input` /
`.inputs` from their `Service` subclass, not to `extend InputBuilder`
themselves.

## `Assistant::Refinements::StringBlankness`

Defined in `lib/assistant/refinements/string_blankness.rb:9`. **Internal**.
Users must not `using` this refinement directly; the refinement may be
replaced with another implementation in any 1.x release.

## Execute callbacks (S1)

Class-level DSL on `Assistant::Service`, **new in 1.0**:

| Signature                                       | Stability | Notes                                                                                  |
|-------------------------------------------------|-----------|----------------------------------------------------------------------------------------|
| `Service.before_execute(&block)`                | Frozen    | Block runs after validation, before `#execute`. Block is `instance_exec`'d on the service. |
| `Service.after_execute(&block)`                 | Frozen    | Block runs after `#execute` returns; receives the result as a block argument.          |
| `Service.around_execute(&block)`                | Frozen    | Block is `instance_exec`'d with a `&blk` argument that yields to the inner stack.      |

Hook error semantics: errors raised inside any hook are caught and logged
via `add_log(level: :error, source: :hook, …)`; they never propagate out of
`#run`. See S1 in [`02-features.md`](./02-features.md).

## Service composition (S2)

Instance-level helper on `Assistant::Service`, **new in 1.0**:

| Signature                                              | Stability | Notes                                                                |
|--------------------------------------------------------|-----------|----------------------------------------------------------------------|
| `#call_service(klass, **inputs) -> Assistant::Service` | Frozen    | Constructs, runs, merges logs, returns the inner instance. If the inner service has errors, the outer service's status becomes `:with_errors`. |

## Instrumentation notifier (S3)

`Assistant.notifier=` and `Assistant.notifier` (documented above). The
following events are emitted, with payload always carrying
`:service_class` and `:duration_s`:

- `:service_started`
- `:service_validated`
- `:service_executed`
- `:service_failed`

The event set is **Frozen** for 1.0. Adding events requires a minor with a
deprecation cycle on any payload removals.

## Input snapshot (S4)

Instance-level helper on `Assistant::Service`, **new in 1.0**:

| Signature                          | Stability | Notes                                                                              |
|------------------------------------|-----------|------------------------------------------------------------------------------------|
| `#input_snapshot -> Data`          | Frozen    | Returns a `Data.define(*declared_input_names).new(**post_default_inputs)` instance. Reflects post-`default:` / post-`allow_nil:` values. |

## `bin/assistant-rbs` (CLI)

Bundled CLI shipped under `bin/`, **new in 1.0**. Generates per-class RBS
signatures for `Assistant::Service` subclasses so Steep can type-check
user code.

| Invocation                                  | Stability     | Notes                                                                                  |
|---------------------------------------------|---------------|----------------------------------------------------------------------------------------|
| `bin/assistant-rbs PATH [--output sig/]`    | Experimental  | Scans `PATH` for `Assistant::Service` subclasses; emits `sig/<class>.rbs` with `def name: () -> Type` and `def name?: () -> bool` per declared input. Multi-type `type:` produces a union. Idempotent. |

Labelled **Experimental** in 1.0 because the output format may evolve in
1.x as RBS support for richer types matures.

## Semver contract for 1.x

- **Patch (1.0.x)**: bug fixes, doc updates, internal refactors that do not
  change observable behaviour.
- **Minor (1.x.0)**: additive API; new `input` options, new `LogItem`
  predicates, new `Service` hooks. No removals.
- **Major (2.0.0)**: removals, renames, behaviour changes that break the
  contract above.

## Deprecation policy

1. Any deprecation lands in a 1.x minor with a `Kernel.warn` + a
   `CHANGELOG.md` "Deprecated" entry **and** an entry in `docs/deprecations.md`
   (created when first needed).
2. Deprecated symbols stay for **at least one further minor** before removal
   in the next major.
3. Every deprecation must ship with a documented migration recipe.

## Changes vs. 0.1.0 (summary)

| Change                                                                              | Type             | Notes                                                                                  |
|-------------------------------------------------------------------------------------|------------------|----------------------------------------------------------------------------------------|
| `Service#logs` reader                                                               | Additive         | M4. New in 1.0.                                                                        |
| `input(..., default:)` and `input(..., allow_nil:)`                                 | Additive         | M1, M2. See [`02-features.md`](./02-features.md).                                      |
| `input(..., type: [A, B])` (array of allowed types)                                 | Additive         | M3.                                                                                    |
| `input(..., optional:)`                                                             | Additive         | M7.                                                                                    |
| `LogList#log_item_info / _warning / _error` shorthands                              | Additive         | M5.                                                                                    |
| `Service.before_execute / after_execute / around_execute`                           | Additive         | S1 (promoted to Must).                                                                 |
| `Service#call_service`                                                              | Additive         | S2 (promoted to Must).                                                                 |
| `Assistant.notifier=` / `Assistant.notifier`                                        | Additive         | S3 (promoted to Must).                                                                 |
| `Service#input_snapshot`                                                            | Additive         | S4 (promoted to Must).                                                                 |
| `bin/assistant-rbs` CLI                                                             | Additive (Experimental) | M11.                                                                             |
| Result hash shape                                                                   | Frozen as-is     | No change; a `Result` value object is deferred to 2.x (Q1).                            |
| `valid_required_*?` canonical name + `valid_require_*?` deprecation                 | **Breaking-soft** | M9 (Q2 decision). Old name still works in 1.x with `Kernel.warn`; removed in 2.0.      |
| `LogItem.new` raises on invalid attrs                                               | **Breaking**     | M10 (Q8 decision). See [`06-migration-0x-to-1.md`](./06-migration-0x-to-1.md).         |
| RBS canonical; Steep required day one                                               | Tooling          | Q6 decision.                                                                           |

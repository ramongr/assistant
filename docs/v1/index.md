<!-- markdownlint-disable MD013 MD024 -->
> **Historical record.** Plans and API for the 1.0.0 release — shipped 2026-06-26.
> See the [release announcement](https://github.com/ramongr/assistant/issues/213) and the [CHANGELOG](../../CHANGELOG.md).

# assistant v1 — Historical Record

## Release record

| Item               | Detail                                                                                   |
|--------------------|------------------------------------------------------------------------------------------|
| Version            | `1.0.0`                                                                                  |
| Release date       | 2026-06-26                                                                               |
| RC tag             | `v1.0.0.rc1` — run [27554209442](https://github.com/ramongr/assistant/actions/runs/27554209442) |
| RubyGems           | https://rubygems.org/gems/assistant/versions/1.0.0                                      |
| GitHub Release     | https://github.com/ramongr/assistant/releases/tag/v1.0.0                                |
| Announcement issue | https://github.com/ramongr/assistant/issues/213                                         |

---

## API surface (Frozen at 1.0.0)

### Stability labels

- **Frozen** — covered by semver from 1.0.0 onward. Breaking changes require a 2.0.
- **Experimental** — public but subject to change in a 1.x minor with a deprecation cycle.
- **Internal** — not part of the contract; do not rely on it.

### `Assistant` (module)

| Symbol                          | Stability             | Notes                                                  |
|---------------------------------|-----------------------|--------------------------------------------------------|
| `Assistant::VERSION`            | Frozen                | String, follows semver. `lib/assistant/version.rb:4`.  |
| `Assistant.notifier`            | Frozen *(new in 1.0)* | Reader for the configured instrumentation proc. Default: no-op proc. |
| `Assistant.notifier=(callable)` | Frozen *(new in 1.0)* | Writer. Accepts any object responding to `#call(event, payload)`. |

### `Assistant::Service`

#### Class-level

| Signature                                          | Stability | Source                              |
|----------------------------------------------------|-----------|-------------------------------------|
| `Service.run(**inputs) -> Hash`                    | Frozen    | `lib/assistant/service.rb:14`       |
| `Service.input(name:, type:, required: false, if: nil, default: nil, allow_nil: false)` | Frozen | `lib/assistant/input_builder.rb:20` |
| `Service.inputs(names:, type:, **options)`         | Frozen    | `lib/assistant/input_builder.rb:13` |
| `Service.before_execute(&block)`                   | Frozen    | Runs after validation, before `#execute`. Block is `instance_exec`'d on the service. |
| `Service.after_execute(&block)`                    | Frozen    | Runs after `#execute`; receives the result as a block argument. |
| `Service.around_execute(&block)`                   | Frozen    | `instance_exec`'d with a `&blk` argument that yields to the inner stack. |

#### Instance-level

| Signature                                | Stability             | Source                        |
|------------------------------------------|-----------------------|-------------------------------|
| `#initialize(**inputs)`                  | Frozen                | `lib/assistant/service.rb:19` |
| `#run -> Hash`                           | Frozen                | `lib/assistant/service.rb:24` |
| `#result -> Object` (memoized)           | Frozen                | `lib/assistant/service.rb:35` |
| `#success? -> Boolean`                   | Frozen                | `lib/assistant/service.rb:39` |
| `#failure? -> Boolean`                   | Frozen                | `lib/assistant/service.rb:43` |
| `#status -> :ok / :with_warnings / :with_errors` | Frozen      | `lib/assistant/service.rb:47` |
| `#logs -> Array<Assistant::LogItem>`     | Frozen *(new in 1.0)* | `attr_reader :logs`           |
| `#infos / #warnings / #errors`           | Frozen                | via `LogList`                 |
| `#execute -> Object` (override)          | Frozen                | `lib/assistant/service.rb:61` |
| `#validate -> void` (override)           | Frozen                | `lib/assistant/service.rb:63` |
| `#call_service(klass, **inputs) -> Assistant::Service` | Frozen *(new in 1.0)* | Constructs, runs, merges logs. Errors in inner service propagate to outer. |
| `#input_snapshot -> Data`                | Frozen *(new in 1.0)* | `Data.define(*declared_input_names).new(**post_default_inputs)` |

#### Generated per-input methods

For every `input :name, type: T` declaration, the following are Frozen:

- `#name` — getter.
- `#name?` — present-and-truthy predicate; whitespace-only strings treated as missing.
- `#valid_type_name?`
- `#valid_required_name?` — generated only when `required: true` (canonical name since 1.0).
- `#valid_require_name?` — **Deprecated in 1.0**, removed in 2.0. Emits a one-time `Kernel.warn` per call site.
- `#valid_required_conditional_name?` — generated when `required: true` and `if:` is supplied.
- `#valid_require_conditional_name?` — **Deprecated in 1.0**, removed in 2.0.

#### Result hash shape

```ruby
# Success
{ result: <Object>, status: :ok | :with_warnings, warnings: Array<LogItem> }

# Failure
{ errors: Array<LogItem>, result: nil, status: :with_errors }
```

### `Assistant::LogItem`

| Signature                                                                | Stability             | Source                         |
|--------------------------------------------------------------------------|-----------------------|--------------------------------|
| `LogItem.new(level:, source:, detail:, message:, trace: nil)`            | Frozen *(raises in 1.0)* | `lib/assistant/log_item.rb:10` |
| `#level / #source / #detail / #message / #trace`                         | Frozen                | `lib/assistant/log_item.rb:8`  |
| `#info? / #warning? / #error?`                                           | Frozen                | `lib/assistant/log_item.rb:26` |
| `#valid? / #valid_level? / #valid_source? / #valid_detail? / #valid_message?` | Frozen          | `lib/assistant/log_item.rb:18` |
| `#item -> Hash`                                                          | Frozen                | `lib/assistant/log_item.rb:22` |
| `LogItem::VALID_LEVELS` → `%i[info warning error]`                       | Frozen                | `lib/assistant/log_item.rb:6`  |

### `Assistant::LogList` (mixin)

| Signature                                                   | Stability             | Source                        |
|-------------------------------------------------------------|-----------------------|-------------------------------|
| `#add_log(level:, source:, detail:, message:, trace: nil)`  | Frozen                | `lib/assistant/log_list.rb:6` |
| `#merge_logs(logs:)`                                        | Frozen                | `lib/assistant/log_list.rb:10` |
| `#log_item_error_initialize(attr_name:, message:)`          | Frozen                | `lib/assistant/log_list.rb:16` |
| `#log_item_info(source:, detail:, message:, trace: nil)`    | Frozen *(new in 1.0)* |                               |
| `#log_item_warning(source:, detail:, message:, trace: nil)` | Frozen *(new in 1.0)* |                               |
| `#log_item_error(source:, detail:, message:, trace: nil)`   | Frozen *(new in 1.0)* |                               |
| `#infos / #warnings / #errors`                              | Frozen                | `lib/assistant/log_list.rb:20` |

### Instrumentation events (S3)

Events emitted via `Assistant.notifier`; payload always carries `:service_class` and `:duration_s`:

- `:service_started`
- `:service_validated`
- `:service_executed`
- `:service_failed`

### `bin/assistant-rbs` (CLI)

| Invocation                               | Stability    | Notes                                                                                     |
|------------------------------------------|--------------|-------------------------------------------------------------------------------------------|
| `bin/assistant-rbs PATH [--output sig/]` | Experimental | Scans `PATH` for `Assistant::Service` subclasses; emits `sig/<class>.rbs` per input. Idempotent. |

### Semver contract for 1.x

- **Patch (1.0.x)**: bug fixes, doc updates, internal refactors — no observable behaviour change.
- **Minor (1.x.0)**: additive API. No removals.
- **Major (2.0.0)**: removals, renames, behaviour changes.

### Deprecation policy

1. Deprecations land in a 1.x minor with a `Kernel.warn` + `CHANGELOG.md` entry + entry in `docs/deprecations.md`.
2. Deprecated symbols stay for at least one further minor before removal in the next major.
3. Every deprecation ships with a documented migration recipe.

---

## Migration from 0.x to 1.0

Three mechanical breaking changes. Everything else is additive.

### B1. `LogItem.new` raises on invalid construction

- **Before** (0.1.0): `LogItem.new(level: '', ...)` succeeded; `#valid?` returned `false`.
- **After** (1.0.0): raises `ArgumentError` listing every failing attribute.
- **Migration**: audit every direct `LogItem.new` / `add_log` call site to confirm `level` is one of `:info`, `:warning`, `:error` and all four required attrs are non-empty. The `#valid?` family is retained for introspection.

### B2. `valid_require_*?` predicate deprecation

- **Before** (0.1.0): only `#valid_require_<name>?` existed.
- **After** (1.0.0): canonical name is `#valid_required_<name>?`; old name is aliased but emits a one-time `Kernel.warn` per call site. Removed in 2.0.
- **Migration**: rename direct calls. Most users never call these directly (the gem drives them internally); no action required for those users.

### B3. `LogList#merge_logs` is keyword-only

- **Before** (0.1.0): `merge_logs(other.logs)` positional.
- **After** (1.0.0): `merge_logs(logs: other.logs)` keyword-only.
- **Migration**:
  ```sh
  # Anywhere you compose log lists:
  #   foo.merge_logs(bar.logs)  ->  foo.merge_logs(logs: bar.logs)
  ```
  `Service.input` / `Service.inputs` leading positional name is **unchanged**.

### TL;DR rewrite checklist

1. `merge_logs(other.logs)` → `merge_logs(logs: other.logs)`
2. Audit direct `LogItem.new` / `add_log` call sites for valid attrs.
3. Rename `valid_require_*?` → `valid_required_*?` at any direct call sites.

See also: `docs/deprecations.md` for the ongoing deprecation log.

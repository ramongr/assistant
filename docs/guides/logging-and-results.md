---
title: Logging and results
parent: Guides
nav_order: 3
---

<!-- markdownlint-disable MD013 MD024 -->
# Logging and results

> **TL;DR** — Every service maintains a `#logs` timeline of
> `Assistant::LogItem`s. Use `log_item_info / _warning / _error` to
> add entries, `#logs` / `#infos` / `#warnings` / `#errors` to read
> them, and the result hash returned by `.run` to consume the
> service from outside. `LogItem.new` raises `ArgumentError` for
> invalid attributes (M10) — prefer the helpers.

This guide covers the data model, the writer helpers, the reader
predicates, and the shape of the result hash. See the
[Validation guide](./validation.md) for *when* to log a warning vs.
an error.

## `Assistant::LogItem` at a glance

Every entry on `#logs` is an `Assistant::LogItem` with the following
fields:

| Field      | Type                           | Notes                                                          |
|------------|--------------------------------|----------------------------------------------------------------|
| `level`    | `Symbol`                       | One of `:info`, `:warning`, `:error`.                          |
| `source`   | `Symbol`                       | High-level subsystem (`:initialize`, `:execute`, `:hook`, ...).|
| `detail`   | `Symbol`                       | Finer-grained tag; usually an input attribute name.            |
| `message`  | `String`                       | Human-readable text.                                           |
| `trace`    | `Array<String>` or `nil`       | Optional backtrace captured at construction.                   |

Constraints (enforced strictly in 1.0 — M10):

- `source != detail`.
- `source` and `detail` must each be non-empty.
- `message` must contain at least one non-whitespace character.
- `level` must be one of `Assistant::LogItem::VALID_LEVELS`.

```ruby
Assistant::LogItem::VALID_LEVELS
# => [:info, :warning, :error]
```

## Writing log entries

The three shorthand helpers (M5) are the recommended call sites
inside `#validate` and `#execute`:

```ruby
class CreateUser < Assistant::Service
  input :email, type: String, required: true
  input :age,   type: Integer, allow_nil: true, default: nil

  def validate
    return if email.include?('@')

    log_item_error(source: :validate, detail: :email, message: 'invalid email')
  end

  def execute
    log_item_info(source: :execute, detail: :age, message: "age=#{age.inspect}")
    log_item_warning(source: :execute, detail: :age, message: 'age missing') if age.nil?

    { id: 42, email:, age: }
  end
end
```

`add_log(level:, source:, detail:, message:, trace: nil)` is the
generic form when you need to set the level dynamically:

```ruby
level = problem.severe? ? :error : :warning
add_log(level:, source: :execute, detail: :payment, message: problem.to_s)
```

`#log_item_error_initialize(attr_name:, message:)` is used internally
by the generated `valid_required_*?` / `valid_type_*?` validators to
record per-input errors. Service code can call it directly when an
ad-hoc validation needs the same `:initialize` source as the
declarative checks.

## Reading log entries

A service exposes three readers, one per level, plus the full
timeline:

| Method        | Returns                              |
|---------------|--------------------------------------|
| `#logs`       | `Array<LogItem>` — every entry, in insertion order. |
| `#infos`      | `Array<LogItem>` — entries with `level == :info`.   |
| `#warnings`   | `Array<LogItem>` — entries with `level == :warning`.|
| `#errors`     | `Array<LogItem>` — entries with `level == :error`.  |

```ruby
service = CreateUser.new(email: 'a@b.com')
service.run

service.logs.size      # => however many entries
service.infos.first.message
service.warnings.any?
service.errors.empty?
```

`#status` is derived from `#errors` and `#warnings`:

- `:with_errors` if `#errors.any?`.
- `:with_warnings` if `#warnings.any?` and no errors.
- `:ok` otherwise.

`#success?` is `true` for `:ok` and `:with_warnings`; `#failure?` is
`true` only for `:with_errors`.

## The result hash

`Service.run` (and `Service#run`) returns one of two shapes:

```ruby
# Success — status is :ok or :with_warnings
{ result: <Object>, status: :ok | :with_warnings, warnings: Array<LogItem> }

# Failure — :with_errors
{ result: nil, status: :with_errors, errors: Array<LogItem> }
```

The success shape always includes `:warnings` (possibly empty); the
failure shape always includes `:errors` (always non-empty) and
`result: nil`. Pattern-matching is the cleanest way to consume it:

```ruby
case CreateUser.run(email: 'a@b.com')
in { result:, status: :ok }
  result
in { result:, status: :with_warnings, warnings: }
  WarningsLogger.log(warnings)
  result
in { errors:, status: :with_errors }
  raise Errors::InvalidRequest, errors.map(&:message).join(', ')
end
```

`#infos` are intentionally **not** part of the result hash. They live
on the service instance for inspection (and for tests), but the
public contract is the warnings/errors split.

## Merging logs across services

`#merge_logs(logs:)` concatenates another timeline onto the current
service's `#logs`. It's mostly used by `#call_service` (see
[`composing-services.md`](./composing-services.md)), but you can call
it directly when you need to forward log items from a non-`Service`
collaborator:

```ruby
def execute
  outcome = MyLibrary.do_thing
  merge_logs(logs: outcome.log_items.map { |item| Assistant::LogItem.new(**item) })
  outcome.value
end
```

> **M12.** `#merge_logs` is keyword-only in 1.0. Passing positional
> arguments raises `ArgumentError`. The
> [migration guide](https://github.com/ramongr/assistant/blob/main/docs/v1/06-migration-0x-to-1.md) covers the
> mechanical rewrite.

## Inspecting an entry

Every `LogItem` has a `#item` method that returns a `Hash` view —
handy for JSON serialization or test assertions:

```ruby
service.errors.first.item
# => { level: :error, source: :validate, detail: :email,
#      message: "invalid email", trace: nil }
```

## Common pitfalls

- **Pushing onto `@logs` directly.** Don't — always go through the
  helpers so the M10 strict construction runs and so future
  middleware (e.g. an instrumentation hook around `#add_log`) can
  see the entry.
- **Using `LogItem.new` with `source == detail`.** Raises
  `ArgumentError`. Pick distinct symbols.
- **Treating `#infos` as part of the contract.** They're for
  introspection only; the result hash never includes them.
- **Calling `merge_logs(other.logs)` (positional).** M12 requires
  the keyword form: `merge_logs(logs: other.logs)`.

## See also

- [Validation guide](./validation.md) — choosing warning vs. error,
  conditional checks, `#validate` mechanics.
- [Composing services](./composing-services.md) — how `#call_service`
  merges inner logs into the outer timeline.
- [API reference: LogItem](../api-reference.md#assistantlogitem).
- [API reference: LogList](../api-reference.md#assistantloglist).
- [Migration guide](https://github.com/ramongr/assistant/blob/main/docs/v1/06-migration-0x-to-1.md) for M10 + M12.

<!-- markdownlint-disable MD013 MD024 -->
# Validation

> **TL;DR** — Declarative `input` checks (`type:`, `required:`,
> `if:`, etc.) run automatically before `#execute`. For everything
> else, override `#validate` and call `log_item_error(...)` to
> short-circuit, or `log_item_warning(...)` to flag a recoverable
> issue. `LogItem.new` raises `ArgumentError` for invalid attributes
> in 1.0 — use the helpers, not `LogItem.new` directly.

This guide covers the validation surface beyond the declarative
options on [`input`](./inputs.md): the `validate` hook, the
warning-vs-error decision, the strict `LogItem` constructor, and
conditional patterns.

## What runs automatically

For every `Service.input :name, type: T, required: ..., if: ...`,
the gem generates and runs:

- `#valid_type_name?` — type check (or multi-type with M3 union).
- `#valid_required_name?` — presence check, when `required: true`.
- `#valid_required_conditional_name?` — presence + predicate, when
  `required: true` *and* `if:` are both supplied.

`#run` calls every `valid_required_*?`, `valid_required_conditional_*?`,
and `valid_type_*?` method that matches by naming convention before
calling your `#validate`. Failures are logged as error-level
`LogItem`s and short-circuit `#execute`.

## Adding your own checks with `#validate`

Override `#validate` to log domain-specific errors:

```ruby
class CreateUser < Assistant::Service
  input :email, type: String, required: true

  def validate
    return if email.include?('@')

    log_item_error(source: :validate, detail: :email, message: 'must contain @')
  end

  def execute
    { email: }
  end
end

CreateUser.run(email: 'a@b.com').fetch(:status) # => :ok
CreateUser.run(email: 'oops').fetch(:status)    # => :with_errors
```

`#validate` runs **after** the declarative checks. If a declarative
check already added an error, your `#validate` still runs (it has the
chance to surface additional context), but `#execute` is skipped.

## Warning vs. error: how to choose

| Level     | Helper                  | Effect                                                                          |
|-----------|-------------------------|---------------------------------------------------------------------------------|
| `:info`   | `log_item_info(...)`    | Recorded on `#logs`; does not affect `#status`.                                 |
| `:warning`| `log_item_warning(...)` | Flips `#status` from `:ok` to `:with_warnings`; `#execute` still runs.          |
| `:error`  | `log_item_error(...)`   | Flips `#status` to `:with_errors`; `#execute` is **skipped**, `#result` is nil. |

Rule of thumb:

- **Use an error** when continuing would produce an invalid or
  misleading result (`#execute` would have to handle the bad state).
- **Use a warning** when the result is still meaningful but the
  caller should know something is off (a missing optional input, an
  in-progress migration shape, a deprecated value).

A worked example:

```ruby
class CreateUser < Assistant::Service
  input :email, type: String,  required: true
  input :age,   type: Integer, allow_nil: true, default: nil

  def validate
    log_item_error(source: :validate, detail: :email, message: 'invalid email') unless email.include?('@')
    log_item_warning(source: :validate, detail: :age, message: 'age missing') if age.nil?
  end

  def execute
    { email:, age: }
  end
end

CreateUser.run(email: 'a@b.com').fetch(:status)
# => :with_warnings — age is missing, but we still build the result

CreateUser.run(email: 'oops').fetch(:status)
# => :with_errors — execute is skipped
```

## Conditional requirements

When a presence check should fire only sometimes, combine
`required: true` with `if:`:

```ruby
class UpdateUser < Assistant::Service
  input :role,   type: Symbol, default: :member
  input :reason, type: String, required: true, if: ->(_value) { true }

  def execute
    { role:, reason: }
  end
end

UpdateUser.run(role: :member).fetch(:status)
# => :with_errors — predicate is truthy, so :reason is required

UpdateUser.run(role: :member, reason: 'audit cleanup').fetch(:status)
# => :ok
```

The `if:` predicate is called with the *input's own value*. The
validator requires the input to be present **and** the predicate to
be truthy — so the canonical use is "I need this to be present
*when* some other condition holds". See
[`inputs.md`](./inputs.md#if-conditional-requirement) for the
inverse pattern.

## `LogItem.new` raises in 1.0 (M10)

Constructing a `LogItem` directly with invalid attributes now raises
`ArgumentError`. The `#valid?` family is kept for introspection but
always returns `true` after a successful `new`:

```ruby
Assistant::LogItem.new(level: :info, source: :a, detail: :b, message: 'ok').valid?
# => true

begin
  Assistant::LogItem.new(level: :info, source: :a, detail: :b, message: '')
rescue ArgumentError => e
  e.message # => "invalid LogItem: message must be present"
end
```

Inside a `Service`, you almost never need `LogItem.new` directly:
`log_item_info(...)`, `log_item_warning(...)`, `log_item_error(...)`,
and `add_log(level:, source:, detail:, message:)` build the item and
append it to `#logs` for you. See
[`logging-and-results.md`](./logging-and-results.md) for the full
catalogue.

## Common pitfalls

- **Returning `false` from `#validate` to signal failure.** The hook's
  return value is ignored. The only way to fail is to log an
  error-level `LogItem`.
- **Calling `raise` inside `#validate` or `#execute`.** Don't —
  `assistant` is soft-fail. Convert expected failures into log items.
  Unexpected exceptions propagate (the gem catches exceptions only
  in `before_execute` / `around_execute` / `after_execute` hooks).
- **Building `LogItem.new(...)` and pushing it onto `#logs`.** Use the
  helpers; they apply the same M10 strict construction and keep your
  call sites readable.
- **Forgetting that `#validate` runs even when a declarative check
  already failed.** Either guard `#validate` with `return if
  errors.any?`, or design it to add complementary errors.

## See also

- [Inputs guide](./inputs.md) — `required:`, `if:`, multi-type, the
  generated `valid_*` predicates.
- [Logging and results](./logging-and-results.md) — the helpers, the
  full result hash, log filtering.
- [API reference: LogItem](../api-reference.md#assistantlogitem).
- [API reference: LogList](../api-reference.md#assistantloglist).

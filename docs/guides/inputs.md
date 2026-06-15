<!-- markdownlint-disable MD013 MD024 -->
# Inputs

> **TL;DR** — Declare every input with `input :name, type: Type` at the
> top of your service class. Inputs are positional in the DSL but the
> service is constructed with keyword arguments. Use `required:`,
> `optional:`, `default:`, `allow_nil:`, `if:`, and array types
> (`type: [String, Symbol]`) to describe the shape exactly. `Steep`
> users get per-class RBS signatures via `bundle exec assistant-rbs`.

This guide covers every option you can pass to `input` (and the bulk
`inputs` helper). See [`api-reference.md`](../api-reference.md#class-methods)
for the canonical signatures and stability labels.

## The DSL at a glance

```ruby
class CreateUser < Assistant::Service
  input  :email,    type: String,  required: true
  input  :name,     type: String,  required: true
  input  :age,      type: Integer, allow_nil: true, default: nil
  input  :role,     type: Symbol,  default: :member
  inputs %i[street city], type: String, optional: true

  def execute
    # email, name, age, role, street, city are all readers here
    { email:, name:, age:, role:, street:, city: }
  end
end
```

Three things to notice:

1. **`input` and `inputs` take a leading positional name** (`:email`,
   `%i[street city]`). Every other DSL option is a keyword argument.
   This is the only place in the gem where a positional argument
   survives the keyword-only DSL — see
   [`api-reference.md`](../api-reference.md#class-methods).
2. **The constructor is keyword-only.** You call
   `CreateUser.run(email: 'a@b.com', name: 'Alice')`, never
   `CreateUser.run('a@b.com', 'Alice')`.
3. **Per-input methods are generated for you.** For every `input :name`
   you get `#name`, `#name?`, `#valid_type_name?`, and (when
   `required: true`) `#valid_required_name?`. See
   [`api-reference.md`](../api-reference.md#generated-per-input-methods).

## `type:` — the only required option

Every input must declare a `type:`. The most common values are plain
classes:

```ruby
input :email, type: String
input :age,   type: Integer
input :tags,  type: Array
```

A `type:` mismatch logs an error and short-circuits `#execute`:

```ruby
class TouchEmail < Assistant::Service
  input :email, type: String

  def execute
    email.upcase
  end
end

TouchEmail.run(email: 42)
# => { result: nil, status: :with_errors,
#      errors: [#<LogItem detail: :email,
#                       message: "Service argument with name email is not a String but Integer">] }
```

### Multi-type inputs

Pass an array of classes when more than one is acceptable:

```ruby
class TouchIdentifier < Assistant::Service
  input :id, type: [String, Integer]

  def execute
    id.to_s
  end
end

TouchIdentifier.run(id: 'abc').fetch(:result) # => "abc"
TouchIdentifier.run(id: 42).fetch(:result)    # => "42"
TouchIdentifier.run(id: :nope).fetch(:status) # => :with_errors
```

The error message lists every accepted type.

## `required: true`

Mark an input required and the gem generates a
`#valid_required_<name>?` validator. Missing or whitespace-only string
values log an error:

```ruby
class CreateUser < Assistant::Service
  input :email, type: String, required: true

  def execute
    { email: }
  end
end

CreateUser.run(email: '')
# => { result: nil, status: :with_errors,
#      errors: [#<LogItem detail: :email,
#                       message: "Service is missing argument with name email">] }

CreateUser.run(email: 'a@b.com')
# => { result: { email: "a@b.com" }, status: :ok, warnings: [] }
```

The deprecated 0.x name `#valid_require_<name>?` still works in 1.x —
calls emit a one-time `Kernel.warn` per call site and delegate to the
canonical predicate. See [`docs/deprecations.md`](../deprecations.md).

## `default:`

Provide a fallback when the caller omits an input. Pass a callable
(method, lambda, or proc) to compute the default lazily — `assistant`
warns if you pass a mutable literal like `[]` or `{}` that would be
shared across calls.

```ruby
class TouchRole < Assistant::Service
  input :role, type: Symbol, default: :member

  def execute
    role
  end
end

TouchRole.run.fetch(:result)             # => :member
TouchRole.run(role: :admin).fetch(:result) # => :admin
```

Lazy defaults are invoked with no arguments:

```ruby
input :token, type: String, default: -> { SecureRandom.uuid }
```

A `default:` provider that takes arguments raises `ArgumentError` at
class-definition time.

## `allow_nil:`

By default, `nil` for a typed input logs a type-mismatch error.
`allow_nil: true` makes `nil` a legal value:

```ruby
class TouchAge < Assistant::Service
  input :age, type: Integer, allow_nil: true, default: nil

  def execute
    age
  end
end

TouchAge.run.fetch(:result)            # => nil
TouchAge.run(age: nil).fetch(:result)  # => nil
TouchAge.run(age: 30).fetch(:result)   # => 30
```

Combine with `default:` to express "optional integer that defaults to
nil and may be set to nil explicitly".

## `optional: true`

`optional: true` is a shorthand for "skip the presence check entirely;
do not generate `#valid_required_name?`". It is mutually exclusive
with `required: true`:

```ruby
class TouchNickname < Assistant::Service
  input :nickname, type: String, optional: true

  def execute
    nickname.to_s.upcase
  end
end

TouchNickname.run.fetch(:result)                 # => ""
TouchNickname.run(nickname: 'ada').fetch(:result) # => "ADA"
```

If you actually want a typed-but-nullable value, prefer
`allow_nil: true` plus `default: nil`; reserve `optional: true` for
inputs whose absence simply means "don't bother".

## `if:` — conditional requirement

`if:` combined with `required: true` makes the presence check fire
only when the predicate returns truthy. The predicate is called with
the input's current value:

```ruby
class CreateUser < Assistant::Service
  input :role,  type: Symbol, default: :member
  input :email, type: String, required: true, if: ->(_value) { caller_wants_email? }

  def execute
    { email:, role: }
  end

  private

  def caller_wants_email?
    role == :admin
  end
end
```

> **Predicate semantics.** Under the hood the validator requires
> `email` to be present **and** the predicate to return truthy. If you
> want the inverse — "email is allowed-but-not-required when role is
> admin" — combine `optional: true` with a manual `validate` check
> instead. See [`validation.md`](./validation.md) for the manual route.

## `inputs` — bulk declaration

`inputs` takes a list of names and applies the same `type:` /
`options` to all of them. Use it when several inputs share a shape:

```ruby
class ShipAddress < Assistant::Service
  inputs %i[street city zip], type: String, required: true

  def execute
    "#{street}, #{city} #{zip}"
  end
end
```

This is exactly equivalent to writing three `input` calls.

## Reading inputs back: `#input_snapshot`

`#input_snapshot` returns a frozen `Data` instance carrying the
post-default, post-`allow_nil` values. It's useful for forwarding the
inputs of one service into another, for instrumentation, or for tests
that want a structural snapshot:

```ruby
class CreateUser < Assistant::Service
  input :email, type: String, required: true
  input :role,  type: Symbol, default: :member

  def execute
    [input_snapshot.email, input_snapshot.role]
  end
end

CreateUser.run(email: 'a@b.com').fetch(:result)
# => ["a@b.com", :member]
```

See [`composing-services.md`](./composing-services.md) for a worked
example that snapshots the outer service's inputs into an inner one.

## Using `assistant-rbs` for Steep users

`Assistant::Service` is metaprogramming-heavy: per-input methods are
generated at class-definition time by `Service.input`, which means a
generic `.rbs` for `Service` can't know that your `CreateUser#email`
returns `String`. That's R1 in
[`docs/v1/05-quality-and-tooling.md`](https://github.com/ramongr/assistant/blob/main/docs/v1/05-quality-and-tooling.md).

The bundled `assistant-rbs` CLI closes the gap by emitting
per-class `.rbs` files. Run it once after editing your services:

```sh
bundle exec assistant-rbs lib --output sig
```

For the `CreateUser` example above it writes
`sig/CreateUser.rbs` with:

```rbs
class CreateUser < Assistant::Service
  def email: () -> String
  def email?: () -> bool
  def role: () -> Symbol
  def role?: () -> bool
end
```

Multi-type inputs produce union types
(`String | Integer`), and `allow_nil: true` produces nullable types
(`String?`). The generator is idempotent — re-running with no input
changes is a no-op.

The CLI is labelled **Experimental** for 1.0 because its output
format may evolve in 1.x; see
[`api-reference.md`](../api-reference.md#assistant-rbs-cli) for the
stability label.

## Common pitfalls

- **Passing a positional name to the constructor.** `Service.new('a')`
  always raises. Call `Service.new(email: 'a')`, or just use
  `Service.run(email: 'a')`.
- **Sharing a mutable default literal.** `default: []` would share
  one array across calls; the gem warns and recommends a lambda
  (`default: -> { [] }`).
- **Mixing `required: true` with `optional: true`.** They contradict
  each other; the gem raises at class-definition time.
- **Expecting `if:` to inhibit presence.** The validator requires
  presence *and* the predicate. Use `optional: true` plus a `validate`
  hook when you need the inverse.

## See also

- [Validation guide](./validation.md) — `validate` hook, when to log a
  warning vs. error.
- [Logging and results](./logging-and-results.md) — `LogItem`,
  `log_item_*` shorthands, the result hash.
- [Composing services](./composing-services.md) — `call_service`,
  callbacks, `#input_snapshot` between services.
- [API reference: class methods](../api-reference.md#class-methods).
- [API reference: generated per-input methods](../api-reference.md#generated-per-input-methods).

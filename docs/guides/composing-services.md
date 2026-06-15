<!-- markdownlint-disable MD013 MD024 -->
# Composing services

> **TL;DR** — Use `call_service(OtherService, **inputs)` to nest one
> service inside another's `#execute`; logs from the inner service
> are merged into the outer timeline automatically. Use
> `before_execute` / `after_execute` / `around_execute` to share
> cross-cutting concerns at the class level. Register
> `Assistant.notifier =` once to instrument every service. Use
> `#input_snapshot` to forward a read-only view of the inputs to a
> collaborator.

This guide covers the four composition surfaces shipped in 1.0:
service-to-service calls, execute callbacks, the instrumentation
notifier, and the input snapshot.

## `#call_service`: nest one service inside another

`call_service(klass, **inputs)` instantiates `klass`, runs it, merges
its `#logs` into the outer service's timeline, and returns the inner
service instance. It does **not** raise on inner failure — the
outer `#execute` decides what to do based on `inner.success?` /
`inner.failure?` / `inner.result`.

```ruby
class CreateUser < Assistant::Service
  input :email, type: String, required: true
  def execute = { id: 1, email: }
end

class SignUp < Assistant::Service
  input :email, type: String, required: true

  def execute
    user = call_service(CreateUser, email:)
    return if user.failure? # inner errors already on the outer timeline

    { user: user.result, signed_up_at: Time.now }
  end
end

result = SignUp.run(email: 'a@b.com')
result.fetch(:status)              # => :ok
result.fetch(:result)[:user][:id]  # => 1
```

Notes:

- `klass` must be a subclass of `Assistant::Service`. Anything else
  raises `ArgumentError`.
- The inner service's `#logs` are appended to the outer service's
  timeline via `merge_logs(logs: inner.logs)`. Because the outer
  service's `errors` / `warnings` / `status` are derived from its
  full `@logs`, inner errors **automatically** downgrade the outer
  terminal status to `:with_errors`, and inner warnings surface as
  `:with_warnings` — no special handling required.
- `call_service` does **not** rescue exceptions raised by the inner
  service's `#execute` (or by the configured `Assistant.notifier`).
  Wrap in `begin/rescue` and record via `add_log(level: :error, ...)`
  if the inner service may raise.
- `call_service` always calls `inner.run`, so calling it twice would
  re-execute the inner service.

## Execute callbacks

Three class-level DSL methods register callbacks around `#execute`.
Hooks are evaluated in the context of the service instance.

```ruby
class CreateUser < Assistant::Service
  input :email, type: String, required: true

  before_execute do
    log_item_info(source: :hook, detail: :before, message: "starting #{email}")
  end

  around_execute do |&blk|
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    value = blk.call
    log_item_info(source: :hook, detail: :around,
                  message: "took #{Process.clock_gettime(Process::CLOCK_MONOTONIC) - started}s")
    value
  end

  after_execute do |result|
    log_item_info(source: :hook, detail: :after, message: "result=#{result.inspect}")
  end

  def execute = { id: 1, email: }
end
```

Behavior:

- **Order:** `before_execute` hooks run in declaration order; then
  `around_execute` hooks wrap the chain with the **first-declared**
  hook as the outermost layer; finally `after_execute` hooks run
  with the execute result as the single positional argument.
- **Inheritance:** subclasses inherit a `dup` of each parent's hook
  arrays. Adding hooks in a subclass does not affect the parent.
- **Exceptions:** a `StandardError` raised inside any hook is logged
  with `level: :error, source: :hook, detail: <hook_type>` and the
  remaining hooks still fire. An `around_execute` hook that raises
  before yielding to its continuation produces `nil` for that layer
  and outer hooks still wrap normally.
- **Missing block:** registering a hook without a block raises
  `ArgumentError` at class-definition time.

## Instrumentation notifier

Assign a callable to `Assistant.notifier =` to receive a fixed set
of events for **every** service execution:

```ruby
Assistant.notifier = lambda do |event, payload|
  StatsD.increment("assistant.#{event}",
                   tags: ["service:#{payload[:service_class]}"])
  StatsD.timing("assistant.duration_s.#{event}",
                payload[:duration_s] * 1000.0,
                tags: ["service:#{payload[:service_class]}"])
end
```

Events (frozen for 1.0):

| Event                | When                                            |
|----------------------|-------------------------------------------------|
| `:service_started`   | Top of `#run`, before any validation.           |
| `:service_validated` | After declarative + `#validate` checks pass.    |
| `:service_executed`  | Success path — after `#execute` returns.        |
| `:service_failed`    | Failure path — `#execute` was skipped.          |

Payload always includes:

- `:service_class` — the `Service` subclass.
- `:duration_s` — Float seconds since the start of `#run`
  (`Process::CLOCK_MONOTONIC`).

The notifier is treated as untrusted infrastructure: any
`StandardError` it raises is rescued and warned (`Kernel.warn`),
so a misconfigured notifier cannot tear down every service in the
process. `SystemExit` / `Interrupt` propagate.

To disable instrumentation entirely, restore the default no-op:

```ruby
Assistant.notifier = Assistant::DEFAULT_NOTIFIER
```

## `#input_snapshot`

`#input_snapshot` returns a read-only `Data` view of the service's
declared inputs (post-`default:` / post-`allow_nil:`). It's the
canonical way to hand a value object to a collaborator without
exposing the full service instance:

```ruby
class CreateUser < Assistant::Service
  input :email, type: String, required: true
  input :role,  type: Symbol, default: :member

  def execute
    Mailer.welcome(input_snapshot)
    { id: 1, **input_snapshot.to_h }
  end
end

snapshot = CreateUser.new(email: 'a@b.com').tap(&:run).input_snapshot
snapshot.email # => "a@b.com"
snapshot.role  # => :member
snapshot.to_h  # => { email: "a@b.com", role: :member }

snapshot.email = 'x' # => NoMethodError (Data is structurally immutable)
```

Notes:

- Members are exactly the keys of `input_definitions` — extra keyword
  arguments to `#initialize` that have no `input` declaration are
  excluded so the snapshot mirrors the public DSL.
- A declared input with no default and no caller-supplied value
  appears with `nil`, mirroring the per-input getter.
- The snapshot class is memoized at the class level via
  `Service.input_snapshot_class`, so repeated calls are cheap.
- `Data` is structurally immutable. Mutable member values (an
  `Array` passed as an input, say) keep their normal mutability —
  the snapshot does not deep-freeze.

## Common pitfalls

- **Forgetting that `call_service` doesn't fail the outer service.**
  If the inner failure should also fail the outer, check
  `inner.failure?` (or `inner.errors.any?`) and call
  `log_item_error(...)` in your `#execute`.
- **Re-running `inner` after `call_service`.** `inner.run` was
  already called; calling it again will re-execute and double-log.
- **Mutating `#input_snapshot` member values.** They share identity
  with the underlying inputs. Treat the snapshot as a view, not a
  defensive copy.
- **Putting validation in `before_execute`.** Use `#validate` — it
  short-circuits `#execute` on errors. Hooks log but don't change
  flow.
- **Raising from a notifier.** It's swallowed (with a `warn`).
  Non-`StandardError` exceptions still propagate, so don't use
  `Kernel#exit`.

## See also

- [Inputs guide](./inputs.md) — `Service.input` / `Service.inputs`
  and `#input_snapshot`.
- [Validation guide](./validation.md) — `#validate`, conditional
  requirements.
- [Logging and results](./logging-and-results.md) — what
  `merge_logs(logs:)` does, the result hash shape.
- [API reference](../api-reference.md#assistantservice) for the
  full callback / call_service / notifier surfaces.

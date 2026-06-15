# Execute callbacks

`before_execute` / `after_execute` / `around_execute` fire around the
`#execute` body — see the [Composing services guide](../guides/composing-services.md#execute-callbacks)
for the full contract.

An audit logger and a wall-time wrapper, combined:

```ruby
class AuditedService < Assistant::Service
  input :user_id, type: Integer, required: true

  before_execute do
    log_item_info(source: :audit, detail: :start, message: "user=#{user_id}")
  end

  after_execute do
    log_item_info(source: :audit, detail: :finish, message: "user=#{user_id}")
  end

  around_execute do |cont|
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    cont.call
    elapsed_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1000).round(1)
    log_item_info(source: :audit, detail: :timing, message: "#{elapsed_ms}ms")
  end

  def execute
    # ... business logic ...
  end
end
```

Failure semantics:

* `before_execute` callbacks run **before** `#execute`. Logging an
  error from a `before_execute` does **not** prevent `#execute` from
  running — it just becomes part of the result hash. Use the
  declarative `valid_*_*?` family or `#validate` when you need to
  short-circuit.
* `around_execute` blocks **must** call `cont.call` (or `yield_*`)
  exactly once. Skipping it silently drops the inner result.
* If a hook itself raises, the exception propagates out of `#run`
  uncaught — hooks are not soft-failed.

{: .note }
> A runnable `examples/execute_callbacks/` script + regression test
> ships in
> [P10](https://github.com/ramongr/assistant/blob/main/docs/v1/08-github-pages.md#p6p12-examples-one-pr-per-example)
> of the GitHub Pages plan.

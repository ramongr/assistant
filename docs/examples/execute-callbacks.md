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

  after_execute do |_result|
    log_item_info(source: :audit, detail: :finish, message: "user=#{user_id}")
  end

  around_execute do |&blk|
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    inner = blk.call
    elapsed_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1000).round(1)
    log_item_info(source: :audit, detail: :timing, message: "#{elapsed_ms}ms")
    inner
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
* `around_execute` blocks receive the inner continuation as the block
  argument (`&blk`) and **must** call it exactly once. Skipping
  `blk.call` silently drops the inner result.
* `after_execute` blocks receive the `#execute` return value as their
  single positional arg.
* If a hook itself raises, `Assistant::Service` rescues the
  `StandardError` and logs it as
  `source: :hook, detail: :before_execute|:around_execute|:after_execute`
  — execution of subsequent hooks continues.

> Source: [`examples/execute_callbacks/`](https://github.com/ramongr/assistant/tree/main/examples/execute_callbacks) ·
> Test: [`test/examples/execute_callbacks_example_test.rb`](https://github.com/ramongr/assistant/blob/main/test/examples/execute_callbacks_example_test.rb)

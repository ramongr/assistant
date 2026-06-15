# Sidekiq worker

A Sidekiq worker that runs a service idempotently and routes warnings
and errors to separate sinks:

```ruby
class CreateUserWorker
  include Sidekiq::Worker
  sidekiq_options retry: 5, queue: :default

  def perform(user_attrs)
    case CreateUser.run(**user_attrs.transform_keys(&:to_sym))
    in { result:, status: :ok }
      # Done. Sidekiq sees no exception, no retry.
    in { result:, status: :with_warnings, warnings: }
      WarningsSink.publish(worker: self.class.name, items: warnings.map(&:item))
    in { errors:, status: :with_errors }
      # Permanent business-rule failure: don't retry, surface to ops.
      ErrorsSink.publish(worker: self.class.name, items: errors.map(&:item))
    end
  end
end
```

Notes:

* The worker **never re-raises** for `:with_errors`. Validation /
  business-rule failures are not transient and shouldn't burn Sidekiq
  retries. Let true exceptions (network, database) propagate.
* `LogItem#item` returns plain symbols/strings, which serialize
  cleanly to JSON / your APM tool.
* For idempotency, keep `CreateUser` purely declarative: read the
  caller's identifier, look up existing state, no-op when already
  satisfied.

> Source: [`examples/sidekiq_worker/`](https://github.com/ramongr/assistant/tree/main/examples/sidekiq_worker) ·
> Test: [`test/examples/sidekiq_worker_example_test.rb`](https://github.com/ramongr/assistant/blob/main/test/examples/sidekiq_worker_example_test.rb)

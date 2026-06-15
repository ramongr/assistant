# Sidekiq worker

How to wrap an `Assistant::Service` in a Sidekiq worker that routes
warnings and errors to separate sinks instead of re-raising into the
retry loop. The matching site page is
[`docs/examples/sidekiq-worker.md`](../../docs/examples/sidekiq-worker.md);
this directory is the runnable mirror referenced from that page.

## Files

| File | Role |
| --- | --- |
| [`create_user.rb`](./create_user.rb) | The service: `email` + `name` inputs, fails when the email is missing `@`, demotes to `:with_warnings` when the name is all-lowercase. |
| [`fake_sidekiq.rb`](./fake_sidekiq.rb) | Stub of `Sidekiq::Worker` + `sidekiq_options` so the example runs without the real `sidekiq` gem on the gemfile. The stub stores options on the class so tests can assert on `retry:` / `queue:`. |
| [`create_user_worker.rb`](./create_user_worker.rb) | The worker class, byte-identical to the docs snippet. Aliases the namespaced service + sinks to top-level constants. Publishes to `SidekiqWorkerExample::WarningsSink` / `ErrorsSink` (both module singletons with a class-level array). |

## Why a fake Sidekiq?

The teaching point of the example is the **case-match + sink routing**,
not the Sidekiq dispatcher. Adding the `sidekiq` gem as a runtime dep
would force the gem's CI matrix to install Redis just to exercise three
case-match branches. The fake module hands back enough of the API
(`include Sidekiq::Worker`, `sidekiq_options(retry:, queue:)`) for the
worker class to load and run synchronously under Minitest.

## Running it manually

```ruby
$ bundle exec ruby -Ilib -rexamples/sidekiq_worker/create_user_worker -e '
  CreateUserWorker.new.perform(email: "a@b.com", name: "Alice")
  CreateUserWorker.new.perform(email: "a@b.com", name: "alice")
  CreateUserWorker.new.perform(email: "oops",    name: "Bob")
  pp warnings: SidekiqWorkerExample::WarningsSink.published,
     errors:   SidekiqWorkerExample::ErrorsSink.published
'
```

The regression test
[`test/examples/sidekiq_worker_example_test.rb`](../../test/examples/sidekiq_worker_example_test.rb)
invokes `CreateUserWorker.new.perform({...})` for each branch and
asserts on the sink contents.

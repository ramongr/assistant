# Instrumentation notifier example

How to wire `Assistant.notifier=` to an arbitrary callable so every
service run dispatches the four lifecycle events (`:service_started`,
`:service_validated`, and exactly one of `:service_executed` /
`:service_failed`) without coupling the gem to any specific
instrumentation backend.

Companion to the
[Instrumentation notifier docs page](../../docs/examples/instrumentation-notifier.md)
(P11 of [`docs/v1/index.md`](../../docs/v1/index.md#p6p12-examples-one-pr-per-example)).

Start with the [getting started guide](../../docs/getting-started.md) if this
is your first Assistant service. Rendered docs:
<https://ramongr.github.io/assistant/#/examples/instrumentation-notifier>.

## Files

| File                     | Role                                                                                                            |
| ------------------------ | --------------------------------------------------------------------------------------------------------------- |
| `create_user.rb`         | Minimal `Assistant::Service` whose happy and failure paths trigger `:service_executed` and `:service_failed`.   |
| `notifier_example.rb`    | Installs a capturing-array notifier, runs the service twice, returns the recorded `[event, payload]` tuples.    |
| `../../test/examples/instrumentation_notifier_example_test.rb` | Pins the event sequence on both paths and the `:service_class` / `:duration_s` payload contract. |

## What the test pins

* Happy path emits exactly `%i[service_started service_validated service_executed]`.
* Failure path (`email: nil`) emits exactly `%i[service_started service_validated service_failed]` — the validator logs the error before `#execute`, so `:service_validated` still fires.
* Every payload carries `service_class:` (the `CreateUser` class) and `duration_s:` (a non-negative `Float`). No `:errors`, no `:id`, no `:started_at` — the
  frozen-for-1.0 payload contract is exactly those two keys, per
  [`docs/api-reference.md#instrumentation-notifier`](../../docs/api-reference.md#instrumentation-notifier).
* A notifier callable that raises `StandardError` does not propagate; the run still completes and the gem warns to `$stderr` instead.
* `Assistant.notifier = nil` in `ensure` restores the no-op default so subsequent runs (and other tests) start from a clean slate.

## Run it

```sh
bundle exec ruby -Ilib -rexamples/instrumentation_notifier/notifier_example -e \
  'pp InstrumentationNotifierExample::NotifierExample.run'
```

Prints both event sequences and the payload keys.

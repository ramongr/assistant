# Instrumentation notifier

`Assistant.notifier=` accepts any object responding to `#call(event,
payload)`. Set it once at boot to wire every service into your
existing instrumentation pipeline — see the [Composing services
guide](../guides/composing-services.md#instrumentation-notifier)
for the contract and the
[API reference](../api-reference.md#instrumentation-notifier) for the
event list.

Wiring it to an `ActiveSupport::Notifications`-shaped sink:

```ruby
Assistant.notifier = ->(event, payload) {
  ActiveSupport::Notifications.instrument("assistant.#{event}", payload)
}
```

A fake sink for tests:

```ruby
events = []
Assistant.notifier = ->(event, payload) { events << [event, payload] }

CreateUser.run(email: 'a@b.com', name: 'Alice')

events.map(&:first)
# => [:service_started, :service_validated, :service_executed]
```

A failure path emits `:service_failed` instead of `:service_executed`:

```ruby
events.clear
CreateUser.run(email: nil, name: 'Alice')

events.map(&:first)
# => [:service_started, :service_validated, :service_failed]
```

Payload shape for every event is exactly two keys: `service_class:`
(the `Assistant::Service` subclass) and `duration_s:` (a `Float`
seconds since `#run` started). The event set and its payload contract
are **Frozen** for 1.0 — see the
[full payload table](../api-reference.md#instrumentation-notifier).

> **Warning** — Notifier callables are rescued from `StandardError`;
> any exception they raise is `warn`-ed but doesn't fail the service.
> Don't put control flow in the notifier.

> Source: [`examples/instrumentation_notifier/`](https://github.com/ramongr/assistant/tree/main/examples/instrumentation_notifier) ·
> Test: [`test/examples/instrumentation_notifier_example_test.rb`](https://github.com/ramongr/assistant/blob/main/test/examples/instrumentation_notifier_example_test.rb)

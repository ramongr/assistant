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

Payload shape for every event includes `service:` (the class), `id:`
(per-run UUID), `started_at:`, plus event-specific keys (`duration_ms:`
on `:service_executed` and `:service_failed`, `errors:` on
`:service_failed`). See the
[full payload table](../api-reference.md#instrumentation-notifier) for
the exhaustive list.

> **Warning** — Notifier callables are rescued from `StandardError`;
> any exception they raise is `warn`-ed but doesn't fail the service.
> Don't put control flow in the notifier.

{: .note }
> A runnable `examples/instrumentation_notifier/` script + integration
> test ships in
> [P11](https://github.com/ramongr/assistant/blob/main/docs/v1/08-github-pages.md#p6p12-examples-one-pr-per-example)
> of the GitHub Pages plan.

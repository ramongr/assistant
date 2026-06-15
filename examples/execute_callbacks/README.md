# execute_callbacks example

How to use `before_execute` / `after_execute` / `around_execute` hooks to
add cross-cutting behaviour (audit logging + wall-time measurement) to
a service without touching its `#execute` body. Companion to
[`docs/examples/execute-callbacks.md`](../../docs/examples/execute-callbacks.md);
see also the
[Composing services guide](../../docs/guides/composing-services.md#execute-callbacks)
for the full hook contract.

## Files

| File | What it shows |
| --- | --- |
| `audited_service.rb` | A `Service` subclass that registers all three hook types: a before-hook logs `:start`, an after-hook logs `:finish`, and an around-hook logs `:timing` with the elapsed milliseconds. |
| `../../test/examples/execute_callbacks_example_test.rb` | Pins the observable hook order on the log timeline (`:start` → `:timing` → `:finish`) and the format of the `:timing` message. |

## Why the observable order is `start` → `timing` → `finish`

The around-hook brackets `cont.call` (the `#execute` body) but the
`log_item_info(:timing)` line runs *after* `cont.call` returns.
`Assistant::Service#run_execute_with_callbacks` (in
`lib/assistant/service.rb`) wires it as:

1. `run_before_execute_hooks` — emits `:start`.
2. `run_around_execute_chain` — runs `cont.call` (no log yet) → `#execute` → then the `log_item_info(:timing)` line.
3. `run_after_execute_hooks` — emits `:finish`.

## Try it

```sh
bundle exec ruby -Ilib -rexamples/execute_callbacks/audited_service -e '
  svc = ExecuteCallbacksExample::AuditedService.new(user_id: 42)
  svc.run
  svc.infos.each { |log| puts "#{log.detail}: #{log.message}" }
'
```

Expected:

```
start: user=42
timing: <n>ms
finish: user=42
```

# Examples <!-- {docsify-ignore-all} -->

Each entry below shows a small, real-world wiring pattern with a
callout-sized code snippet. Runnable scripts live under
[`examples/<slug>/`](https://github.com/ramongr/assistant/tree/main/examples)
and their regression tests under
[`test/examples/`](https://github.com/ramongr/assistant/tree/main/test/examples).

| Example | Demonstrates |
| --- | --- |
| [Rails service](rails-service.md) | Rails-shaped controller; `case service.run in { result:, status: :ok }`. |
| [CLI handler](cli-handler.md) | `OptionParser` driving a service; exit code derived from `#status`. |
| [Sidekiq worker](sidekiq-worker.md) | Worker class that runs a service; idempotent; logs warnings vs errors separately. |
| [Composing services](composing-services.md) | Outer service uses `call_service` to chain two inner services; log timeline merging. |
| [Execute callbacks](execute-callbacks.md) | `before_execute` audit logger; `around_execute` timing wrapper; failure cases. |
| [Instrumentation notifier](instrumentation-notifier.md) | `Assistant.notifier=` wired to a fake `ActiveSupport::Notifications`-shaped sink. |
| [RBS generator](rbs-generator.md) | Service definition → `bin/assistant-rbs --output sig` → Steep proving generated input reader types. |

Each example is intentionally small enough to be read in one sitting.

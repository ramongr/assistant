---
title: Examples
nav_order: 5
has_children: true
permalink: /examples/
---

# Examples

> **Status:** gallery scaffolding — each entry below ships with a
> runnable script under `examples/<slug>/`, a writeup on this site,
> and a regression test. See
> [P6–P12 of the GitHub Pages plan](https://github.com/ramongr/assistant/blob/main/docs/v1/08-github-pages.md#p6p12-examples-one-pr-per-example)
> for the per-example schedule.

| Example | Demonstrates |
| --- | --- |
| [Rails service](rails-service.md) | Rails-shaped controller; `case service.run in { result:, status: :ok }`. |
| [CLI handler](cli-handler.md) | `OptionParser` driving a service; exit code derived from `#status`. |
| [Sidekiq worker](sidekiq-worker.md) | Worker class that runs a service; idempotent; logs warnings vs errors separately. |
| [Composing services](composing-services.md) | Outer service uses `call_service` to chain two inner services; log timeline merging. |
| [Execute callbacks](execute-callbacks.md) | `before_execute` audit logger; `around_execute` timing wrapper; failure cases. |
| [Instrumentation notifier](instrumentation-notifier.md) | `Assistant.notifier=` wired to a fake `ActiveSupport::Notifications`-shaped sink. |
| [RBS generator](rbs-generator.md) | Service definition → `bin/assistant-rbs --output sig` → Steep proving per-input return types. |

Each example is intentionally small enough to be read in one sitting.
Source for every script lives under
[`examples/`](https://github.com/ramongr/assistant/tree/main/examples)
in the repository.

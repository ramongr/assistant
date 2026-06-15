# Instrumentation notifier

> **Status:** placeholder — ships in
> [P11](https://github.com/ramongr/assistant/blob/main/docs/v1/08-github-pages.md#p6p12-examples-one-pr-per-example) of
> the GitHub Pages plan.

`Assistant.notifier=` wired to a fake `ActiveSupport::Notifications`-shaped sink.

When the runnable script under `examples/instrumentation_notifier/` lands, this
page will include it verbatim via mkdocs `pymdownx.snippets` so the
prose stays in lockstep with the code.

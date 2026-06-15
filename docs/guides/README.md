# Guides

Topic-focused walkthroughs of every part of the Assistant DSL.
Each guide opens with a TL;DR, ships runnable examples mirrored by
tests under `test/docs/<guide>_examples_test.rb`, and ends with a
"common pitfalls" + "see also" section.

- [Inputs](./inputs.md) — `input`/`inputs` DSL, `type:`, `required:`,
  `default:`, `allow_nil:`, `optional:`, `if:` conditional requirement,
  and the `assistant-rbs` Steep recipe.
- [Validation](./validation.md) — auto-checks, `#validate`, warnings
  vs errors, conditional requirements, strict `LogItem.new`.
- [Logging and results](./logging-and-results.md) — `LogItem`,
  levels, `log_item_*` shorthands, `merge_logs`, the result hash.
- [Composing services](./composing-services.md) — `call_service`,
  callbacks, the notifier, `#input_snapshot`.
- [RBS and types](./rbs-and-types.md) — per-class generator, the R1
  metaprogramming limitation, Steep CI hookup.

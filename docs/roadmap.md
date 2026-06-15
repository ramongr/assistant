# Roadmap

The full 1.0 plan lives in
[`docs/v1/`](https://github.com/ramongr/assistant/tree/main/docs/v1) in
the repository. Each file below is a focused planning document; the
index ties them together.

| Doc | What it covers |
| --- | --- |
| [`README.md`](https://github.com/ramongr/assistant/blob/main/docs/v1/README.md) | Plan index and reading order. |
| [`00-overview.md`](https://github.com/ramongr/assistant/blob/main/docs/v1/00-overview.md) | 1.0 goals, non-goals, acceptance criteria. |
| [`01-api-surface.md`](https://github.com/ramongr/assistant/blob/main/docs/v1/01-api-surface.md) | Frozen vs Experimental symbols, stability labels. |
| [`02-features.md`](https://github.com/ramongr/assistant/blob/main/docs/v1/02-features.md) | M1–M13 milestones and the promoted M-S* set. |
| [`03-documentation.md`](https://github.com/ramongr/assistant/blob/main/docs/v1/03-documentation.md) | D1–D5 documentation deliverables. |
| [`04-release-checklist.md`](https://github.com/ramongr/assistant/blob/main/docs/v1/04-release-checklist.md) | Pre-release, RC, release, and post-release steps. |
| [`05-quality-and-tooling.md`](https://github.com/ramongr/assistant/blob/main/docs/v1/05-quality-and-tooling.md) | SimpleCov, RuboCop, Steep, CI matrix. |
| [`06-migration-0x-to-1.md`](https://github.com/ramongr/assistant/blob/main/docs/v1/06-migration-0x-to-1.md) | The three mechanical rewrites required to upgrade. |
| [`07-risks-and-open-questions.md`](https://github.com/ramongr/assistant/blob/main/docs/v1/07-risks-and-open-questions.md) | Known constraints (e.g. R1 RBS limitation) and resolutions. |
| [`08-github-pages.md`](https://github.com/ramongr/assistant/blob/main/docs/v1/08-github-pages.md) | The plan for **this site** (parallel deliverable, not a 1.0 gate). |

## Current snapshot

- 1.0 release plumbing is in flight — the gem is at
  [`1.0.0.rc1`](changelog.md) and the migration recipe is finalised.
- Every "Must" milestone (M1–M13) and every promoted "Should"
  (M-S1–M-S4) has shipped to `main`.
- The mkdocs site you're reading now is P2 of the GitHub Pages plan;
  later phases land the remaining guide / example content.

<!-- markdownlint-disable MD013 -->
# Contributing to `assistant`

Thanks for taking the time to contribute. `assistant` is a small, dependency-free
service-object gem and it intends to stay that way; please read this guide
end-to-end before opening your first pull request.

By participating you agree to abide by the project's
[Code of Conduct](./CODE_OF_CONDUCT.md).

## Quick start

```sh
git clone https://github.com/ramongr/assistant.git
cd assistant
bin/setup            # bundle install + any future bootstrap steps
bundle exec rake     # default task runs the test suite
```

If `bin/console` is more your speed, that boots an IRB session with the gem
preloaded.

## `bin/` developer scripts

The three checked-in scripts under `bin/` are developer conveniences. They
are smoke-tested on every CI run by the `bin/ scripts smoke` job, so they
should always work on a fresh clone.

| Script        | What it does                                                       | Usage                                          |
|---------------|--------------------------------------------------------------------|------------------------------------------------|
| `bin/setup`   | Bash wrapper that runs `bundle install` on a cold checkout.        | `./bin/setup`                                  |
| `bin/console` | Boots IRB with `bundler/setup` + `require 'assistant'` preloaded.  | `bin/console`                                  |
| `bin/version` | Bumps `Assistant::VERSION` in `lib/assistant/version.rb`.          | `bin/version --patch` &#124; `--minor` &#124; `--major` &#124; `--help` |

These scripts are **not packaged with the gem** — they live under `bin/`,
not `exe/`. The only executable that ships in the gem is
`exe/assistant-rbs` (M11). See [`assistant.gemspec`](./assistant.gemspec)
for the `spec.executables` derivation.

## Local checks

Before you push, run the full local pipeline. The CI pipeline mirrors these
tools and rejects pull requests that do not match.

```sh
bundle exec rake test           # Minitest
bundle exec rubocop             # style + lint
bundle exec steep check         # RBS / type-check
bundle exec rake ci             # convenience aggregate (test + rubocop + steep)
```

SimpleCov runs automatically as part of `rake test` and writes its report to
`coverage/`. Coverage is reported in CI but is **not a hard gate**; the long-
term targets (≥98% line, ≥95% branch) are documented in
[`docs/v1/index.md`](./docs/v1/index.md).

## Branch naming

| Branch                       | Use it for                                                 |
|------------------------------|------------------------------------------------------------|
| `feature/m<n>-<slug>`        | A roadmap milestone from [`docs/v1/index.md`](./docs/v1/index.md). |
| `feature/m-s<n>-<slug>`      | A promoted "Should" item (M-S1, M-S2, …).                  |
| `docs/<slug>`                | Documentation-only changes (D1–D5, status sweeps, guides). |
| `chore/<slug>`               | Tooling / housekeeping with no roadmap milestone.          |
| `fix/<slug>` or `bug/<slug>` | Bug fixes that are not part of a milestone.                |
| `refactor/<slug>`            | Internal refactors with no behavior change.                |

## Commit message style

```
<TAG>: <imperative summary, ≤72 chars>

<wrapped body explaining the WHAT and the WHY (not the HOW).
Reference roadmap milestones or issues by ID.>
```

`<TAG>` is one of:

- `M<n>` — a roadmap milestone (e.g. `M11: bin/assistant-rbs per-class RBS
  generator`). Look up the number in [`docs/v1/index.md`](./docs/v1/index.md).
- `M-S<n>` — a promoted "Should" item.
- `D<n>` — a documentation milestone from
  [`docs/v1/index.md`](./docs/v1/index.md).
- `chore:`, `docs:`, `refactor:`, `fix:` — when the change does not map to a
  roadmap entry.

Wrap the body at ~72 columns. Do **not** paste tool output or file lists;
`git diff` already shows that.

## Pull requests

Open the PR against `main`. The PR description follows the template at
[`.github/PULL_REQUEST_TEMPLATE.md`](./.github/PULL_REQUEST_TEMPLATE.md) and
should always cover:

- **Scope** — which milestone / issue this implements (link the roadmap line).
- **What this PR ships** — bullet list of the public-facing changes.
- **Verification** — paste the green tail of `rake test`, `rubocop`, and
  `steep check` (or `rake ci`).
- **Out of scope** — what was deliberately left for later.

Each pull request must:

- [ ] Add or update a `CHANGELOG.md` entry under `[Unreleased]`.
- [ ] Add or update tests in `test/`.
- [ ] Update docs in `docs/` and the relevant `docs/v1/*.md` checklist if a
      roadmap item is closing.
- [ ] Pass `bundle exec rake ci` locally.

CI will run on every push; the `Steep`, `RuboCop`, `Minitest (Ruby 3.4)`, and
`Minitest (Ruby 4.0)` checks are required by branch protection.

## Reporting bugs

Open an issue at <https://github.com/ramongr/assistant/issues>. Please include:

- The version of `assistant` you are using.
- Your Ruby version.
- A minimal, runnable reproduction (ideally a service definition plus the
  exact call that fails).
- The full `result` hash or backtrace.

For security-sensitive reports, follow [`SECURITY.md`](./SECURITY.md) instead
of the public tracker.

## Code of Conduct

Everyone interacting in this project's codebases, issue trackers, chat rooms,
and mailing lists is expected to follow the
[Contributor Covenant Code of Conduct](./CODE_OF_CONDUCT.md). Reports go to
`cerberus.ramon@gmail.com`.

---
name: create-pr
description: Use when opening a GitHub pull request for the assistant gem (e.g. `gh pr create`, "open a PR", "ship this branch"). Ensures local checks pass, only intended files are committed, commit/PR follow the M<num> convention, and the PR is assigned to the GitHub user before returning the URL.
---

# Skill: create-pr

PRs for this repo follow a strict shape. Walk through every step in order.
Skipping any one of them is a defect.

## 1. Verify local checks before pushing

Run all three from the worktree root and confirm each is green. None of these
should be skipped because "the change is small" — the CI gate will reject the
PR anyway.

```sh
bundle exec rake test
bundle exec rubocop
bundle exec steep check --jobs=1
```

If anything fails, fix it on the branch (or revert the offending hunk) before
committing. Do not commit "WIP" or "fix in CI" placeholders.

## 2. Stage only the intended files

Inspect `git status --short` before staging. Explicitly enumerate paths to
`git add` — never run `git add .` or `git add -A`.

**Always exclude** the following even if they appear as untracked or modified:

- Anything under `.opencode/` **except** committed config (`.opencode/.gitignore`,
  `.opencode/opencode.json`) and project-owned skills under
  `.opencode/skills/<name>/`. Transient agent state, scratch files, and
  unrelated skills (e.g. `.opencode/skills/ruby-services/` if not owned by
  this project) stay untracked.
- `.DS_Store`, `*.swp`, `*~`, any local-only debug scripts
- `Gemfile.lock` is fine to commit when an actual dep changed; do not stage it
  for unrelated mechanical updates

If something unrelated was modified during exploration (e.g. accidental
reformat of an untouched file), restore it with `git restore <path>` first.

After staging, re-check with `git diff --cached --stat` and confirm the file
list matches the PR's scope.

## 3. Commit message convention

The repo's commit messages follow:

```
<TAG>: <short imperative summary, <=72 chars>

<wrapped body explaining the WHAT and WHY, not the HOW>
<reference roadmap milestones or issues by ID>
```

`<TAG>` is one of:

- `M<n>` — a v1 roadmap milestone (e.g. `M11: bin/assistant-rbs per-class
  RBS generator`). Look up the number in `docs/v1/02-features.md`.
- `M-S<n>` — a "stretch" / promoted roadmap item.
- `D<n>` — a documentation milestone from `docs/v1/04-documentation.md`.
- A short topic tag like `chore:`, `docs:`, `refactor:` when the change does
  not map to a roadmap item.

The body wraps at ~72 cols and explains the WHY. Do not paste tool output or
file lists — the diff already shows that.

Pre-commit hooks may reject the commit. If they do, fix the issue and create
a **new** commit. Do not `--amend` past hook failures.

## 4. Push and track

```sh
git push -u origin <branch>
```

The branch name should already match the work: `feature/m<n>-<slug>` for
roadmap milestones, or `<topic>/<slug>` otherwise.

## 5. Open the PR

Use `gh pr create` with `--base main`, the explicit `--head <branch>`, a
`--title` that mirrors the lead commit's subject, and a `--body` that covers:

- **Scope** — what milestone / issue this implements (link the roadmap line).
- **What this PR ships** — bullet list of the public-facing changes.
- **Sample output / behavior** — fenced block when the change has a visible
  surface (CLI output, generated artifact, error message).
- **Verification** — the green output of `rake test`, `rubocop`, and
  `steep check`. Paste the actual tail of each command.
- **Out of scope** — what was deliberately left for later (e.g. "M12 changes
  this DSL signature; that ships in its own PR").

Pass the body via a heredoc so newlines and quoting survive:

```sh
gh pr create --base main --head <branch> --title "..." --body "$(cat <<'EOF'
...
EOF
)"
```

## 6. Assign the PR

GitHub does not auto-assign. **Always** assign the PR to the authenticated
user immediately after creation:

```sh
gh pr edit <number> --add-assignee "$(gh api user --jq .login)"
```

Confirm the assignment landed by re-reading the PR URL output — `gh pr edit`
prints the URL on success.

## 7. Return the PR URL

The final message to the user must include the PR URL on its own line so the
terminal renders it as a clickable link. Mention the PR number, the commit
SHA(s) it contains, and the assignee.

## Common pitfalls

- **Committing transient `.opencode/` state** — agent scratch files and skills
  that aren't owned by this repo must never appear in `git status` as staged.
  Project-owned skills under `.opencode/skills/<name>/SKILL.md` are fine to
  commit when they're part of the change.
- **Forgetting to push before `gh pr create`** — `gh` will error with
  `pull request create failed: GraphQL: No commits between main and …`.
  Always `git push -u origin <branch>` first.
- **Skipping the assignee step** — unassigned PRs get lost in the review
  queue. Always run step 6.
- **Empty `--body`** — `gh pr create` will silently use the commit message as
  the body, which usually under-documents the change. Always pass `--body`.
- **`--amend` after a pre-commit hook failure** — the failure already left
  artifacts in the index; create a fresh commit instead.

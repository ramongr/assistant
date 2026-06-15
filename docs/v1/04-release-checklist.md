<!-- markdownlint-disable MD013 MD024 -->
# 04 — Release Checklist for 1.0.0

## Order of operations

1. Resolve every open question in
   [`07-risks-and-open-questions.md`](./07-risks-and-open-questions.md).
2. Land every "must" item from [`02-features.md`](./02-features.md).
3. Land the documentation deliverables in
   [`03-documentation.md`](./03-documentation.md).
4. Cut a `v1.0.0.rc1` tag, smoke-test, then cut `v1.0.0`.

## Pre-release: `assistant.gemspec` updates

- [x] `spec.summary` — replaced the bundler-template line with
      `Tiny, dependency-free soft-fail service objects for Ruby`
      (`assistant.gemspec:16`), matching the README elevator pitch.
- [x] `spec.description` — expanded into a 3-sentence heredoc
      (`assistant.gemspec:17-24`) covering soft-fail semantics, the
      uniform result shape, RBS/Steep posture, and the zero-runtime-deps
      guarantee.
- [x] Added `spec.metadata['documentation_uri'] = 'https://rubydoc.info/gems/assistant'`.
- [x] Added `spec.metadata['bug_tracker_uri'] = 'https://github.com/ramongr/assistant/issues'`.
- [x] Confirmed `spec.metadata['changelog_uri']` still points at
      `CHANGELOG.md` on `main`.
- [x] Confirmed `spec.required_ruby_version = '>= 3.4'` matches both the
      gemspec, `.rubocop.yml`'s `TargetRubyVersion`, and the CI matrix
      floor (`'3.4'`).
- [x] Confirmed `spec.metadata['rubygems_mfa_required']` stays `'true'`.
- [x] `spec.files` glob now excludes `docs/v1/`, `docs/v1.x/`, and
      `examples/` from the packaged gem per the Q9 decision:
  ```ruby
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      f.match(%r{^(test|spec|features|examples|docs/v1(\.x)?)/})
    end
  end
  ```
  Verified locally with `Gem::Specification.load("assistant.gemspec").files`
  — 0 entries match `^docs/v1/`, 0 match `^examples/`.
- [x] Confirmed the M11 CLI is shipped: `spec.bindir = 'exe'` plus the
      `spec.files.grep(%r{^exe/})` for `spec.executables` resolves to
      `["assistant-rbs"]`, with `exe/assistant-rbs` included in
      `spec.files`.
- [x] Added `yard` (development dep) — shipped in D3 at
      `assistant.gemspec:50` (`yard ~> 0.9`).
- [x] Added `simplecov` (development dep) — shipped with the SimpleCov
      slice at `assistant.gemspec:48` (`simplecov ~> 0.22`).
- [x] `steep` (development dep) was already declared pre-1.0 at
      `assistant.gemspec:49` (`steep ~> 2.0`).

## Pre-release: source updates

- [ ] Bump `Assistant::VERSION` to `'1.0.0'` in `lib/assistant/version.rb:4`.
- [ ] Update `bin/version` (if it touches the constant) to keep it green.
- [ ] Move all `[Unreleased]` entries in `CHANGELOG.md` under a new
      `## [1.0.0] - YYYY-MM-DD` heading and add a `## [Unreleased]` empty
      section above it.
- [ ] In `CHANGELOG.md`, add a "Migration" subsection under `[1.0.0]`
      summarizing [`06-migration-0x-to-1.md`](./06-migration-0x-to-1.md).
- [ ] Tag the EOL of `0.x` in `SECURITY.md` (created in
      [`03-documentation.md`](./03-documentation.md)).

## Local pre-flight (run before pushing the tag)

```sh
bin/setup
bundle exec rake test
bundle exec rubocop --parallel
bundle exec rake ci          # aggregate task: test + rubocop + steep
gem build assistant.gemspec
gem install ./assistant-1.0.0.rc1.gem
ruby -e 'require "assistant"; p Assistant::VERSION'
```

All must exit 0. The `gem install` smoke must not require any optional
dependency.

## Pre-release: RC tag

- [ ] Bump `Assistant::VERSION` to `'1.0.0.rc1'` on a release branch.
- [ ] Push the branch, open the PR, get CI green.
- [ ] Tag `v1.0.0.rc1`, push the tag — `.github/workflows/release.yml` will
      build, publish to RubyGems, and create a GitHub Release.
- [ ] Smoke-test in a brand-new Ruby 3.4 project:
  ```sh
  mkdir /tmp/assistant-rc1 && cd /tmp/assistant-rc1
  bundle init
  bundle add assistant --version 1.0.0.rc1
  ruby -r assistant -e 'class S < Assistant::Service; def execute = :ok; end; p S.run'
  bundle exec assistant-rbs . --output sig    # verify CLI works
  ```
- [ ] **No fixed soak period** — tag `v1.0.0` as soon as the smoke-test
      passes and CI on the RC tag is green. If bugs surface post-RC, cut
      additional `rcN` tags until clean.

## Release: 1.0.0 tag

- [ ] Confirm `main` is green and the RC has no open follow-ups.
- [ ] Bump `Assistant::VERSION` to `'1.0.0'`.
- [ ] Commit with message `Release 1.0.0`; push to `main`.
- [ ] Tag `v1.0.0` and push the tag — release workflow takes over.
- [ ] Verify on RubyGems:
  - Version `1.0.0` is listed.
  - The trusted publisher badge is shown.
  - `documentation_uri` and `bug_tracker_uri` resolve.
- [ ] Verify on GitHub:
  - The Release page exists with the auto-generated notes.
  - The `assistant-1.0.0.gem` artifact is attached
    (`.github/workflows/release.yml:46`).

## Post-release

- [ ] Open an `[Unreleased]` PR that bumps `Assistant::VERSION` to
      `'1.0.1.dev'` (or chosen pre-release marker) and adds an empty
      `### Added` / `### Changed` / `### Fixed` skeleton in `CHANGELOG.md`.
- [ ] Pin a "v1.0.0 released" announcement issue and link from the README.
- [ ] Move all "Should" items from [`02-features.md`](./02-features.md) that
      did not land into a fresh `docs/v1.x/` planning folder.
- [ ] Mark `docs/v1/` as historical: add a banner at the top of
      [`README.md`](./README.md) noting "Plans for the 1.0.0 release —
      shipped on YYYY-MM-DD."

## Rollback

If a critical bug is found post-publish:

- [ ] **Do not** `gem yank` unless the bug is a security issue or the gem
      cannot be `require`d at all.
- [ ] Cut `1.0.1` with the fix; document the bug in `CHANGELOG.md` under
      `[1.0.1]` → `### Fixed`.
- [ ] If yank is required, add a `SECURITY.md` advisory entry.

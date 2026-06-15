# Changelog

The full release history is in
[`CHANGELOG.md`](https://github.com/ramongr/assistant/blob/main/CHANGELOG.md)
at the repository root, formatted per
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

The same file is what `assistant.gemspec` points to via
`spec.metadata['changelog_uri']`, so RubyGems shows the identical content
under the gem's **Changelog** tab.

## How to read it

- `[Unreleased]` collects changes that have merged to `main` but have not
  been cut into a release tag.
- Each released version uses an ISO date and groups entries by
  `### Added` / `### Changed` / `### Deprecated` / `### Removed` /
  `### Fixed` / `### Security`.
- `### Changed (Breaking)` callouts mark semver-breaking changes; for
  the 0.x → 1.x sweep, those are catalogued in
  [`docs/v1/06-migration-0x-to-1.md`](https://github.com/ramongr/assistant/blob/main/docs/v1/06-migration-0x-to-1.md).

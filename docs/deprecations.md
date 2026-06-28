# Deprecations

This page tracks every public symbol that is **deprecated** in a 1.x release
and the version in which it will be removed. Each entry includes a 1:1
replacement and the runtime warning users will see.

The deprecation policy is one full minor cycle: anything marked here in
`1.x` is removed in `2.0`.

## Index

| Symbol                                                  | Replacement                                                       | Deprecated in | Removed in |
|---------------------------------------------------------|-------------------------------------------------------------------|---------------|------------|
| `Assistant::Service#valid_require_<name>?`              | `Assistant::Service#valid_required_<name>?`                       | `1.0.0`       | `2.0.0`    |
| `Assistant::Service#valid_require_conditional_<name>?`  | `Assistant::Service#valid_required_conditional_<name>?`           | `1.0.0`       | `2.0.0`    |

---

## `valid_require_<name>?` → `valid_required_<name>?`

**Deprecated in**: `1.0.0`. **Removed in**: `2.0.0`.

### What changed

Per-input requirement validators are now generated under their
grammatically correct names. For each `input :name, required: true`
declaration, `Assistant::Service` subclasses gain:

| Canonical (use this)                          | Deprecated alias (still works, warns once per call site) |
|-----------------------------------------------|----------------------------------------------------------|
| `#valid_required_<name>?`                     | `#valid_require_<name>?`                                 |
| `#valid_required_conditional_<name>?`         | `#valid_require_conditional_<name>?`                     |

Both names refer to the same underlying predicate — the deprecated alias
simply delegates to the canonical method after emitting the deprecation
warning. Return values, side effects, and `log_item_error_initialize`
behaviour are unchanged.

### Runtime warning

```text
assistant: `#valid_require_email?` is deprecated; use `#valid_required_email?` (removed in assistant 2.0)
```

The warning fires through `Kernel.warn` (i.e. on `$stderr`) **once per
textual call site** (`caller_locations(1, 1).first` is keyed by `path +
lineno`). Calling the alias 100 times from the same line yields exactly
one warning; calling it from two different lines yields two warnings.

Internal framework code (`Service#validate_inputs`) calls only the
canonical name, so the warning never fires from inside the gem.

### Migration

Search-and-replace at the call site:

```ruby
# Before
service.valid_require_email?
service.valid_require_conditional_token?

# After
service.valid_required_email?
service.valid_required_conditional_token?
```

If your code overrides one of these predicates (`def valid_require_email?
...`), rename the override to the canonical name. The deprecated alias
will still exist in `1.x` and will continue to delegate to the canonical
method, so an override under the old name is silently bypassed.

### Why

Q2 in
[`docs/v1/index.md`](https://github.com/ramongr/assistant/blob/main/docs/v1/index.md)
was decided in favour of Option B: the new names read better, match
standard English, and are easier to grep for. The old names live one
minor cycle to give downstream services an upgrade window.

See [`docs/v1/index.md`](https://github.com/ramongr/assistant/blob/main/docs/v1/index.md) for the
implementation plan and acceptance criteria.

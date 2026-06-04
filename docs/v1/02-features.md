<!-- markdownlint-disable MD013 MD024 -->
# 02 — Feature Roadmap to 1.0

Each item lists rationale, sketched API, test plan, risk, and an owner
placeholder. Status uses the legend in [`README.md`](./README.md).

---

## Must (blockers for 1.0)

### M1. `input(..., default:)`

- **Rationale**: today an optional input is just `nil` if not supplied.
  Defaults are the single most-requested service-object affordance.
- **API sketch**:
  ```ruby
  input :limit,     type: Integer, default: 25
  input :now,       type: Time,    default: -> { Time.now }
  input :tags,      type: Array,   default: -> { [] }
  input :threshold, type: Float,   default: -> { ENV.fetch("THRESHOLD", "0.5").to_f }
  ```

#### Formal semantics

The `default:` option attaches a **default provider** to an input. The
provider is consulted exactly once per service instance, during
`#initialize`, before any validator runs.

1. **Trigger condition** — the default provider is invoked **iff** the
   input key is absent from the keyword arguments **or** its value is
   `nil`. Specifically:
   ```ruby
   @inputs[name] = default_for(name) unless @inputs.key?(name) && !@inputs[name].nil?
   ```
   This means an explicit `nil` is treated the same as an omitted key for
   defaulting purposes. The interaction with M2 (`allow_nil:`) is covered
   below.
2. **Provider types** — `default:` accepts one of:
   - **A literal value** (`Integer`, `String`, `Symbol`, `true`, `false`,
     `nil`, frozen `Array`/`Hash`, any other object). The same object
     reference is assigned every time the default fires.
   - **A `Proc` or `Lambda`** with **arity 0**. The proc is `call`ed with
     no arguments. Its return value is assigned to `@inputs[name]`. The
     proc is invoked once per service instance that needs the default —
     never memoised across instances.
   - Any other callable (e.g. a `Method` object) is rejected with
     `ArgumentError` at class-definition time. This keeps the surface
     intentionally narrow.
3. **Evaluation context** — proc defaults are `call`ed in the **lexical
   context where they were defined** (the standard `Proc#call` semantics).
   They are **not** `instance_exec`'d on the service. This means a default
   cannot read other inputs:
   ```ruby
   # NOT supported — defaults cannot depend on other inputs in 1.0.
   input :a, type: Integer
   input :b, type: Integer, default: -> { a * 2 }   # NameError at run time
   ```
   Inter-input defaults are deferred to 1.x (see "Open follow-ups" below).
4. **Ordering inside `#initialize`**:
   1. Assign the raw `**args` hash to `@inputs`.
   2. For each declared input in declaration order, fire its default
      provider if the trigger condition above is met.
   3. Return from `#initialize` with `@logs = []`.
   Validators (`valid_type_*?`, `valid_require_*?`,
   `valid_require_conditional_*?`) do not run until `#run` is called, so
   they see the post-defaulted `@inputs`.
5. **Interaction with type validation** — defaults are **not** exempt
   from `valid_type_*?`. A default whose type does not match `type:`
   produces the same `"Service argument with name X is not a Y but Z"`
   error as if the user had supplied that value directly. Authors are
   expected to keep their defaults type-correct; the library will not
   coerce.
6. **Interaction with `required: true`** — a default **satisfies** the
   requirement check. If a default is present, `valid_require_*?` always
   passes regardless of whether the caller supplied the key. The
   combination is allowed and idiomatic for "this input must have a
   value, here's a sensible one":
   ```ruby
   input :limit, type: Integer, required: true, default: 25
   ```
7. **Interaction with the `if:` conditional requirement** — the `if:`
   predicate is evaluated **after** defaulting, so it always sees a
   non-`nil` value when a default is configured. The predicate's contract
   is unchanged from 0.1.0.
8. **Interaction with M2 (`allow_nil:`)** — when `allow_nil: true` is set
   alongside `default:`, an **explicit `nil`** from the caller is still
   replaced by the default; the `default:` always wins over an explicit
   `nil`. Rationale: a default exists precisely to fill the absent-or-nil
   hole. If a caller wants to assert "no value", they must omit the key
   *and* configure `allow_nil: true` on an input without a default — at
   which point the input is plainly `nil`. This is documented as a
   deliberate, non-obvious rule in `docs/guides/inputs.md`.
9. **Interaction with M7 (`optional:`)** — orthogonal. `optional: true,
   default: X` is legal and means "no value required from the caller; if
   one is not supplied, use X". `required: true, default: X` is also
   legal (see point 6). `optional: false, default: X` is equivalent to
   `required: true, default: X`.
10. **Mutability and aliasing** — the library does **not** `dup` or
    `freeze` literal default values. A mutable literal default
    (e.g. `default: []`) is **shared** across every service instance that
    fires it. This is consistent with Ruby's `def foo(x = [])`
    semantics for default expressions evaluated once at parse time …
    except Ruby re-evaluates `[]` on every call. To avoid the footgun,
    the documentation strongly recommends a proc for any mutable default
    (`default: -> { [] }`), and `Service.input` emits a one-time
    `Kernel.warn` at class-definition time when a non-frozen `Array` or
    `Hash` literal is passed as a default:
    ```text
    assistant: input :tags has a mutable Array default; use `default: -> { [] }` to avoid sharing across instances
    ```
    The warning is informational, not an error, and can be silenced by
    freezing the literal (`default: [].freeze`) or wrapping it in a proc.
11. **Errors raised at class-definition time** — `Service.input` raises
    `ArgumentError` immediately (before any method is generated) when:
    - `default:` is a `Proc` with non-zero arity.
    - `default:` is a callable other than `Proc`/`Lambda` (e.g. `Method`).
    No `ArgumentError` is raised for a type-mismatched literal default;
    that surfaces at `#run` time via `valid_type_*?`, consistent with
    point 5.
12. **Inspectability** — the per-input default configuration is stored
    on the class in a frozen registry accessible via
    `Service.input_definitions[:name][:default]` (an existing internal
    hash, formalised in 1.0). Users may read it for introspection; it is
    labelled **Experimental** in
    [`01-api-surface.md`](./01-api-surface.md) so we can change the
    representation in a 1.x minor.

#### Worked examples

```ruby
class FetchUsers < Assistant::Service
  input :limit,  type: Integer, required: true, default: 25
  input :cursor, type: String,  optional: true                  # no default -> nil
  input :now,    type: Time,    default: -> { Time.now }

  def execute
    { limit:, cursor:, now: }
  end
end

FetchUsers.run                          # => { result: { limit: 25, cursor: nil, now: <Time> }, status: :ok, warnings: [] }
FetchUsers.run(limit: nil)              # => same as above; explicit nil triggers default
FetchUsers.run(limit: 100, cursor: 'c') # => result reflects supplied values
FetchUsers.run(limit: 'a-lot')          # => :with_errors, valid_type_limit? fails
```

#### Open follow-ups (out of scope for M1, tracked for 1.x)

- Inter-input defaults (defaults that read other already-defaulted
  inputs). Likely API: `default: ->(inputs) { inputs[:a] * 2 }` with
  documented topological order. Tracked in
  [`07-risks-and-open-questions.md`](./07-risks-and-open-questions.md)
  Q10 (to be added when scheduled).
- A `default_from_env:` shorthand. Considered and rejected for 1.0 — a
  proc is already terse enough.

#### Test plan

Extend `test/assistant/input_builder_test.rb` with cases for:

- Literal default applied when key absent.
- Literal default applied when key explicitly `nil`.
- Caller-supplied non-nil value beats the default.
- Proc default invoked exactly once per instance (use a counter).
- Proc default with non-zero arity raises `ArgumentError` at class
  definition.
- Non-`Proc` callable (`method(:foo)`) raises `ArgumentError` at class
  definition.
- Default + `required: true` succeeds with no caller args.
- Default + `required: true` succeeds with explicit `nil`.
- Default + type mismatch surfaces via `valid_type_*?`, not at init.
- Default + `if:` predicate sees the defaulted value.
- Default + `allow_nil: true`: explicit `nil` is replaced by default.
- Default + `optional: true`: no error when key absent.
- Mutable literal default emits the one-time class-definition warning.
- Frozen literal default does **not** emit the warning.
- Proc default does **not** emit the warning.

#### Risk

Low–medium. The required changes are localised to
`lib/assistant/input_builder.rb` (default registration + arity check)
and `lib/assistant/service.rb:19` (defaulting pass in `#initialize`).
The non-obvious rule is the "explicit `nil` is replaced by default
even with `allow_nil: true`" interaction (point 8); it must be loudly
documented to avoid surprise.

- **Owner**: _TBD_.
- **Status**: `[ ]`.

### M2. `input(..., allow_nil:)`

- **Rationale**: today, `valid_type_*?` returns `true` when the input is
  absent because `send("name?")` is `false`; but if a user explicitly passes
  `nil`, behaviour is identical. We need an explicit knob so optional inputs
  can either reject `nil` or accept it.
- **API sketch**:
  ```ruby
  input :note, type: String, allow_nil: true   # nil is OK, otherwise must be String
  input :note, type: String                    # nil is treated as missing (current behaviour)
  ```
- **Test plan**: cases for explicit `nil` with and without `allow_nil:`, with
  and without `required: true`.
- **Risk**: low–medium. Must not change behaviour when `allow_nil:` is
  omitted (back-compat).
- **Owner**: _TBD_.
- **Status**: `[ ]`.

### M3. `input(..., type: [A, B])`

- **Rationale**: real-world inputs are often "Integer or Float", "Symbol or
  String".
- **API sketch**:
  ```ruby
  input :amount, type: [Integer, Float]
  ```
  `valid_type_amount?` passes if `@inputs[:amount].is_a?` matches **any** of
  the listed types.
- **Test plan**: success on each member type, failure on a non-member,
  message format `"... is not one of [Integer, Float] but String"`.
- **Risk**: low. The type-check call site is a single line in
  `lib/assistant/input_builder.rb:73`.
- **Owner**: _TBD_.
- **Status**: `[ ]`.

### M4. Public `Service#logs` reader

- **Rationale**: today, callers must reach into `@logs` via
  `instance_variable_get` to inspect the full log timeline (info + warning +
  error). The result hash only exposes `warnings` or `errors`.
- **API sketch**:
  ```ruby
  class MyService < Assistant::Service; end
  s = MyService.new
  s.run
  s.logs # => Array<Assistant::LogItem>, all levels
  ```
- **Test plan**: assert `logs` is exposed, returns the same array as
  `infos + warnings + errors` modulo ordering.
- **Risk**: trivial. Add `attr_reader :logs` to `Assistant::Service`.
- **Owner**: _TBD_.
- **Status**: `[ ]`.

### M5. Generic `log_item_*` shorthands on `LogList`

- **Rationale**: `log_item_error_initialize` already exists
  (`lib/assistant/log_list.rb:16`). Add level/source pairs that are commonly
  used so service authors stop hand-rolling `add_log(level: :warning, ...)`
  every time.
- **API sketch**:
  ```ruby
  log_item_warning(source: :execute, detail: :rate_limited, message: "slow down")
  log_item_error(source: :execute,   detail: :db_unreachable, message: "down")
  log_item_info(source: :execute,    detail: :cache_hit,     message: "ok")
  ```
- **Test plan**: extend `test/assistant/log_list_test.rb` with one example
  per level; assert the resulting `LogItem` is shaped correctly.
- **Risk**: low. Pure additions on `LogList`.
- **Owner**: _TBD_.
- **Status**: `[ ]`.

#### Open follow-ups (out of scope for M5, tracked for 1.x)

- **Rename `log_item_error_initialize`** to avoid visual collision with the
  new generated `log_item_error`. The existing helper
  (`lib/assistant/log_list.rb:16`) is not `log_item_error` + an `initialize`
  suffix in behaviour: it hard-codes `source: :initialize` and takes
  `attr_name:` instead of `source:/detail:/trace:`. After M5 ships,
  `log_item_error` and `log_item_error_initialize` live side by side with
  different signatures, which is easy to confuse at a call site. Candidate
  new name: `log_initialize_error`. Treat as an additive 1.x change (add
  the new name, alias the old, deprecate via `Kernel.warn`, remove in 2.0)
  to stay consistent with the M9 deprecation pattern.

### M6. Lazy load of `LogItem` from `lib/assistant.rb`

- **Rationale**: `lib/assistant.rb:3` eagerly requires `log_item`,
  `service`, `version`, but the directory layout now has more siblings.
  Group the requires explicitly and add `LogList` to the entry point so
  `Assistant::LogList` is reachable without requiring `service` first.
- **Test plan**: add a Minitest case `require "assistant"` then
  `defined?(Assistant::LogList)`.
- **Risk**: trivial.
- **Owner**: _TBD_.
- **Status**: `[ ]`.

### M7. `input(..., optional:)`

- **Rationale**: today, optionality is implicit — any input without
  `required: true` is silently optional. That is fine for terse code but
  makes intent hard to read at a glance and prevents the DSL from
  distinguishing "deliberately optional" from "forgot to mark required".
  Adding an explicit `optional:` flag gives readers a clear signal and
  lets the DSL raise on contradictory declarations.
- **API sketch**:
  ```ruby
  input :nickname, type: String, optional: true   # explicit; same runtime
                                                  # behaviour as omitting the flag

  input :email, type: String, required: true      # unchanged

  # Contradiction — raises ArgumentError at class-definition time:
  input :foo, type: String, required: true, optional: true
  ```
  Semantics:
  - `optional: true` is the default when neither `required:` nor
    `optional:` is supplied (back-compat).
  - `optional: false` is equivalent to `required: true`.
  - Supplying both `required: true` and `optional: true` raises
    `ArgumentError` from `Service.input` immediately, before any method is
    defined.
  - `optional:` composes with `default:` (M1) and `allow_nil:` (M2)
    without surprises: an optional input with a default uses the default
    when missing; an optional input with `allow_nil: true` accepts an
    explicit `nil`.
- **Test plan**: extend `test/assistant/input_builder_test.rb` with cases
  for:
  - `optional: true` on its own (service runs cleanly with the key
    missing).
  - `optional: false` behaves identically to `required: true` (missing key
    produces the same error message as today).
  - `required: true, optional: true` raises `ArgumentError` at class
    definition time.
  - `optional: true, default: ...` (M1 interaction) — default applied.
  - `optional: true, allow_nil: true` (M2 interaction) — explicit `nil` is
    accepted and the type validator does not log an error.
- **Risk**: low. The flag is sugar over the existing
  `required:`-driven branch in `lib/assistant/input_builder.rb:27`; the
  only new behaviour is the contradiction check, which is a class-level
  guard with no runtime cost.
- **Docs touchpoint**: add to `docs/guides/inputs.md` per
  [`03-documentation.md`](./03-documentation.md) D2; include in the
  [`01-api-surface.md`](./01-api-surface.md) "Changes vs. 0.1.0" table as
  an additive change.
- **Owner**: _TBD_.
- **Status**: `[x]` — landed in `feature/m7-input-optional`.

### M8. Empty `service.rbs` populated

- **Rationale**: `lib/assistant/service.rbs` (`lib/assistant/service.rbs:3`)
  is an empty class declaration and ships in the gem (because the file
  exists in `git`). Users with Steep get a misleading definition.
- **API sketch**: write full RBS for every Frozen symbol in
  [`01-api-surface.md`](./01-api-surface.md). Add sibling files
  `log_item.rbs`, `log_list.rbs`, `input_builder.rbs`, `version.rbs`.
- **Test plan**: `bundle exec steep check` passes as a **required** CI job
  (see [`05-quality-and-tooling.md`](./05-quality-and-tooling.md) — Q6
  decision).
- **Risk**: medium. RBS for the metaprogrammed `input(...)` getters cannot
  be expressed precisely on the gem side; M11 ships a generator so user
  code can be type-checked. Document the limitation in
  `docs/guides/inputs.md`.
- **Owner**: _TBD_.
- **Status**: `[ ]`.

### M9. Deprecate `valid_require_*?` in favour of `valid_required_*?`

- **Rationale**: Q2 in
  [`07-risks-and-open-questions.md`](./07-risks-and-open-questions.md) was
  decided in favour of Option B. The new predicate names read better and
  match standard English; the old names stay one minor for an upgrade
  window.
- **API sketch**:
  ```ruby
  # Generated for `input :email, required: true`:
  #   #valid_required_email?              (new canonical, Frozen)
  #   #valid_require_email?               (alias, Deprecated)
  #
  # Generated for `input :email, required: true, if: ->(v) { ... }`:
  #   #valid_required_conditional_email?  (new canonical, Frozen)
  #   #valid_require_conditional_email?   (alias, Deprecated)
  ```
  Each call to a deprecated alias emits a one-time-per-call-site
  `Kernel.warn` of the form:
  ```text
  assistant: `#valid_require_email?` is deprecated; use `#valid_required_email?` (removed in assistant 2.0)
  ```
  The warning fires once per `caller_locations(1, 1)` location, tracked
  in a `Set` on the singleton class to keep the runtime cost negligible.
- **Test plan**: extend `test/assistant/input_builder_test.rb`:
  - The new name is generated for `required: true`.
  - The new name is generated for `required: true, if: ...`.
  - The old name is generated and returns the same value as the new name.
  - The old name emits exactly one `Kernel.warn` per call site (using
    `assert_output(nil, /deprecated/)` and repeated calls).
- **Risk**: low. Pure DSL change in
  `lib/assistant/input_builder.rb:47` and `:58`. Internal callers in
  `lib/assistant/service.rb:54` migrate to the new name to avoid the
  warning.
- **Docs touchpoint**: seed `docs/deprecations.md` with the first entry,
  per D2 in [`03-documentation.md`](./03-documentation.md). Shipped with
  M9: [`docs/deprecations.md`](../deprecations.md).
- **Owner**: _TBD_.
- **Status**: `[x]` — shipped on `feature/m9-required-deprecation`.

### M10. `LogItem.new` raises on invalid construction

- **Rationale**: Q8 was decided in favour of strict construction. A
  `LogItem` is a tiny value object whose validity is structural; producing
  invalid instances and then asking `#valid?` afterwards is a footgun.
- **API sketch**:
  ```ruby
  Assistant::LogItem.new(level: '', source: :s, detail: :d, message: 'm')
  # => ArgumentError: invalid LogItem: level must be one of [info, warning, error]
  ```
  Validation runs at the end of `#initialize`. Error messages aggregate
  every failing predicate so the caller sees all problems at once. The
  `#valid?` family of predicates is **retained**; in normal flows they
  return `true` post-construction.
- **Test plan**:
  - `LogItem.new` with every individual invalid attr raises with a
    message naming that attr.
  - `LogItem.new` with two invalid attrs raises with both in the message.
  - `LogItem.new` with all attrs valid does not raise and `#valid?` is
    `true`.
  - **Audit test**: a fuzzer-style test exercises every internal call
    site (`log_item_error_initialize`, M5 shorthands once they land,
    `Service` error paths) and asserts no `ArgumentError` escapes.
- **Risk**: medium. This is a **breaking change** vs 0.1.0. Audit
  required for every existing call to `LogItem.new` and to `add_log` to
  ensure validity. Documented as breaking in
  [`06-migration-0x-to-1.md`](./06-migration-0x-to-1.md).
- **Owner**: _TBD_.
- **Status**: `[x]` — shipped on `feature/m10-strict-log-item`.

### M11. `bin/assistant-rbs` per-class RBS generator

- **Rationale**: Q6 made RBS canonical and Steep a required CI job.
  Per R1 in
  [`07-risks-and-open-questions.md`](./07-risks-and-open-questions.md),
  the metaprogrammed per-input getters cannot be expressed in a single
  generic RBS. Ship a CLI users can run to generate accurate sigs for
  their own service classes.
- **API sketch**:
  ```sh
  bin/assistant-rbs lib/             # scan lib/ recursively
  bin/assistant-rbs lib/ --output sig/ --quiet
  ```
  For each `Assistant::Service` subclass found, emit
  `sig/<underscored_class>.rbs` with:
  - `def name: () -> Type` for every declared input.
  - `def name?: () -> bool` for every declared input.
  - Multi-type `type: [A, B]` becomes `A | B`.
  - Inputs not given a `type:` keyword (today this is the only allowed
    form, so this is a guard for a future change) raise
    `RuntimeError`.
  Re-running the CLI overwrites only files it owns; a header comment
  (`# Generated by bin/assistant-rbs; do not edit.`) is the marker.
- **Test plan**:
  - Generator emits the expected `.rbs` for a fixture service with
    single-type, multi-type, and `?`-predicate inputs.
  - Re-running is idempotent (no diff).
  - A handwritten `.rbs` without the marker header is left untouched.
  - Steep happily type-checks a sample `examples/` service whose `.rbs`
    is produced by the CLI.
- **Risk**: medium. The generator touches user code paths; needs to be
  conservative (read-only on files lacking the marker). Marked
  **Experimental** in [`01-api-surface.md`](./01-api-surface.md) so the
  output format can evolve in 1.x.
- **Owner**: _TBD_.
- **Status**: `[ ]`.

### M12. Keyword arguments for every public and internal method

- **Rationale**: 0.1.0 is inconsistent about its calling convention. The
  headline DSL (`Service.input`, `Service.inputs`) takes the attribute
  name as a positional argument while every option after it is a
  keyword. Internal helpers in `InputBuilder` follow the same mixed
  pattern, and `LogList#merge_logs(other_logs)` is purely positional.
  Mixed conventions make signatures harder to read, harder to type with
  RBS (positional + keyword splats produce noisier sigs than pure
  keyword ones), and harder to evolve — every new option that wants to
  sit next to `attr_name` has to be a keyword anyway, so the positional
  slot is a permanent wart. 1.0.0 is the only chance to land this
  without a deprecation cycle (per Q-decision: 0.x EOL on 1.0.0 release
  date), so it becomes a Must.
- **API sketch**:
  ```ruby
  # Before (0.1.0)
  class CreateUser < Assistant::Service
    input  :role,        type: String, default: 'member'
    inputs %i[a b c],    type: Integer, required: true
  end

  # After (1.0.0)
  class CreateUser < Assistant::Service
    input  name:  :role,        type: String, default: 'member'
    inputs names: %i[a b c],    type: Integer, required: true
  end
  ```
  Signature changes:
  - `Service.input(attr_name, type:, **)` →
    `Service.input(name:, type:, **)`.
  - `Service.inputs(attr_names, type:, **)` →
    `Service.inputs(names:, type:, **)`.
  - `LogList#merge_logs(other_logs)` →
    `LogList#merge_logs(logs:)`.
  - All `InputBuilder` helpers
    (`input_getter_meth(attr_name)`,
    `input_checker_meth(attr_name)`,
    `input_type_validator_meth(attr_name, type, **options)`,
    `input_require_validator_meth(attr_name, **options)`,
    `input_require_conditional_meth(attr_name, **options)`,
    `type_validator_body(attr_name, types, allow_nil, message_builder)`,
    `type_mismatch_message_builder(attr_name, types)`) become
    fully keyword: `(name:)`, `(name:, type:, **options)`,
    `(name:, types:, allow_nil:, message_builder:)`, etc.
  - `LogItem#initialize`, `LogList#add_log`,
    `LogList#log_item_error_initialize`, `LogList#log_item_*` shorthands
    (added in M5), `Service.run`, and `Service#initialize` are already
    keyword-only and do not change.
- **Migration**: hard break. The 0.x → 1.0 migration guide
  ([`06-migration-0x-to-1.md`](./06-migration-0x-to-1.md)) gets a
  dedicated section with a `sed`-style recipe:
  ```sh
  # In a service file, rewrite every:
  #   input :foo, ...
  # to:
  #   input name: :foo, ...
  # and every:
  #   inputs %i[a b c], ...
  # to:
  #   inputs names: %i[a b c], ...
  ```
  No runtime shim accepting the old positional form will be shipped —
  this is the same hard-break policy used for M9 (`valid_require_*?`
  removed in 2.0 after a deprecation cycle that we cannot run for M12
  since the change is purely shape, not behaviour). The migration guide
  notes that the change is `git grep`-able and trivially scriptable.
- **Ordering**: lands **last** among the Must-list mechanical changes,
  after M1–M11 and the four promoted Should items (M-S1..M-S4).
  Reasons:
  - It touches every test file in the suite (every `Class.new(Assistant::Service)`
    fixture uses `input :foo, type: …`), so rebasing it on top of all
    other input-related work avoids merge churn during M1/M2/M3/M7.
  - It must come before M11 (RBS generator) so the generator emits sigs
    against the final method shapes; otherwise the generator template
    would need a rewrite.
  - It must come before the Phase 4 docs sweep so the updated examples
    use the new form throughout.
- **Test plan**:
  - Every existing test in `test/assistant/{service,input_builder,log_list,log_item}_test.rb`
    is rewritten in the same PR to use the new keyword form; this is the
    test that the change actually compiles and runs. Suite must remain
    green with the same assertion count (no behaviour drift).
  - New regression test in `test/assistant/input_builder_test.rb`:
    calling `Service.input(:foo, type: String)` (old positional form)
    raises `ArgumentError: missing keyword: :name`, asserting that no
    accidental shim slipped in.
  - New regression test for `LogList#merge_logs(other_logs)` raising
    `ArgumentError: missing keyword: :logs`.
- **Risk**: low semantically (no behaviour change), high mechanically
  (every user file breaks). Mitigated by:
  - Single, well-scoped PR that does only the rename — no behaviour
    edits, no opportunistic refactors. Reviewers can read it as a pure
    signature change.
  - The migration guide entry shipping in the same PR.
  - The 0.x EOL policy ([`04-release-checklist.md`](./04-release-checklist.md))
    being clear that 1.0.0 is a breaking release and no 0.x patches
    will follow.
- **Docs touchpoint**:
  - [`01-api-surface.md`](./01-api-surface.md) — update every signature in
    the API surface table; add a "Changes vs. 0.1.0" entry: _"All
    methods are keyword-only. `Service.input`/`Service.inputs` now take
    `name:`/`names:` as a keyword."_
  - [`06-migration-0x-to-1.md`](./06-migration-0x-to-1.md) — new
    "Keyword-only method signatures" section with the sed recipe and an
    explicit list of every renamed signature.
  - [`03-documentation.md`](./03-documentation.md) — D2 (`guides/inputs.md`)
    and the README quickstart examples updated to the new form during
    Phase 4.
- **Owner**: _TBD_.
- **Status**: `[ ]`.

### M13. Split `Assistant::InputBuilder` into per-concern submodules

- **Rationale**: M7 (`feature/m7-input-optional`, #141) raised
  `Metrics/ModuleLength` to `150` in `.rubocop.yml` to accommodate the
  new `optional:` helpers. The right answer is to split
  `lib/assistant/input_builder.rb` along the lines of the
  responsibilities already implicit in the file (registry, DSL,
  per-option families, per-generator families) so the umbrella module
  shrinks back below the default `100`-line ceiling and the override
  can be removed. Doing this **before M12** keeps the keyword-arg
  signature sweep scoped to small, focused files rather than churning
  a single 190-line umbrella.
- **Scope**: pure structural refactor — no behaviour change, no public
  API change, no test assertion change. `Service` continues to
  `extend Assistant::InputBuilder`; method lookup is unchanged because
  the umbrella `include`s each submodule.
- **File layout**:
  ```text
  lib/assistant/input_builder.rb                       # umbrella: requires + includes
  lib/assistant/input_builder/registry.rb              # Registry submodule
  lib/assistant/input_builder/dsl.rb                   # Dsl (input, inputs)
  lib/assistant/input_builder/default_option.rb        # DefaultOption (M1 trio)
  lib/assistant/input_builder/optional_option.rb       # OptionalOption (M7 trio)
  lib/assistant/input_builder/accessors.rb             # Accessors (refinement-scoped)
  lib/assistant/input_builder/require_validator.rb     # RequireValidator
  lib/assistant/input_builder/type_validator.rb        # TypeValidator
  ```
  Mirrored under `test/assistant/input_builder/` so each submodule has
  its own focused test file; the umbrella `test/assistant/input_builder_test.rb`
  keeps only structural smoke tests (every submodule is included; every
  method is reachable from a fresh `extend`).
- **Test plan**: redistribute the existing tests in
  `test/assistant/input_builder_test.rb` per the table in the M13
  execution plan; the suite must remain green with the same
  assertion count plus a handful of new umbrella smoke assertions.
  Add per-submodule includability tests so an include-order regression
  is caught immediately.
- **Tooling**: remove the `Metrics/ModuleLength: Max: 150` block from
  `.rubocop.yml` once the split lands; CI must be clean against the
  default `100`-line ceiling.
- **Ordering**: lands **before M12**. M11 (RBS CLI) reads
  `Service.input_definitions` from `Registry`; the file move is
  transparent to it.
- **Risk**: low. The lexical refinement
  `using Assistant::Refinements::StringBlankness` narrows from the
  whole module to just `accessors.rb`; existing checker tests cover
  the whitespace path.
- **Owner**: _TBD_.
- **Status**: `[ ]`.

---

## Should (promoted to Must for 1.0)

> All four items below were promoted from "Should" to "Must" during
> planning; they are required to ship 1.0. Implementation order is
> decided during Phase 2.

### M-S1. Around-execute callbacks

- **Rationale**: instrumentation and timing are common cross-cutting needs.
- **API sketch**:
  ```ruby
  class MyService < Assistant::Service
    before_execute { add_log(level: :info, ...) }
    after_execute  { |result| add_log(level: :info, ...) }
    around_execute { |service, &blk| Telemetry.time("svc") { blk.call } }
  end
  ```
- **Risk**: medium. Hook ordering and error semantics must be specified
  precisely. **Decision**: errors raised inside any hook are caught and
  logged via `add_log(level: :error, source: :hook, …)`; they never
  propagate out of `#run`. Around-hook composition uses the inner-most
  block last (declaration order wraps).
- **Status**: `[ ]`.

### M-S2. Service composition primitive

- **Rationale**: composing services today means each caller writes
  ```ruby
  inner = OtherService.new(**); inner.run
  merge_logs(inner.send(:instance_variable_get, :@logs))
  return if inner.failure?
  ```
  Ship a sugar method that does this correctly.
- **API sketch**:
  ```ruby
  def execute
    other = call_service(OtherService, foo: 1)
    return if failure?
    other.result + 1
  end
  ```
  `call_service` constructs, runs, merges logs, and returns the inner
  service instance. If the inner service has errors, the outer service's
  status becomes `:with_errors` automatically.
- **Risk**: medium. Need to be explicit about whether warnings propagate
  (yes) and whether errors are translated (no — they're appended verbatim).
- **Status**: `[ ]`.

### M-S3. Instrumentation hook

- **Rationale**: optional tracing without coupling to a specific notifier.
- **API sketch**:
  ```ruby
  Assistant.notifier = ->(event, payload) { Rails.logger.debug([event, payload].inspect) }
  ```
  Events: `:service_started`, `:service_validated`, `:service_executed`,
  `:service_failed` (Frozen event set for 1.0). Payload always includes
  `:service_class`, `:duration_s`.
- **Risk**: low. Default notifier is a no-op proc.
- **Status**: `[ ]`.

### M-S4. Frozen Data for input snapshot

- **Rationale**: today `@inputs` is a mutable hash. Some users want a
  read-only snapshot of inputs they can pass around safely.
- **API sketch**: `Service#input_snapshot -> Data.define(*declared_input_names).new(...)`.
- **Risk**: medium — interacts with M1 (defaults) and M2 (allow_nil).
- **Status**: `[ ]`.

---

## Won't (deferred past 1.0)

- `[-]` Async / concurrent execution primitive — out of scope for a
  soft-fail service object library; users can wrap a service in any thread
  pool.
- `[-]` Pluggable serializers (JSON / Hash / etc.) — `#run` returning a hash
  is enough; users serialize at the boundary.
- `[-]` Schema DSL for outputs — adds significant API surface for marginal
  benefit.
- `[-]` Rails generators — would require a Railtie and a runtime dependency
  on Rails; stays out of scope per [`00-overview.md`](./00-overview.md).
- `[-]` Built-in i18n for log messages — users wrap `add_log` themselves.

---

## Cross-cutting acceptance criteria for the "must" list

- [ ] Every new feature ships with at least one Minitest test that fails
      without the implementation.
- [ ] Every new feature is referenced from
      [`03-documentation.md`](./03-documentation.md) so the docs PR is not
      forgotten.
- [ ] Every new feature has an entry in `CHANGELOG.md` under
      `[Unreleased]` → `### Added` (or `### Changed`).
- [ ] No new feature introduces a runtime gem dependency.

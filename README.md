# Assistant

[![CI](https://github.com/ramongr/assistant/actions/workflows/ci.yml/badge.svg)](https://github.com/ramongr/assistant/actions/workflows/ci.yml)
[![Gem Version](https://img.shields.io/gem/v/assistant.svg)](https://rubygems.org/gems/assistant)
[![Downloads](https://img.shields.io/gem/dt/assistant.svg)](https://rubygems.org/gems/assistant)
[![Ruby](https://img.shields.io/badge/ruby-%3E%3D%203.4-ruby.svg)](https://www.ruby-lang.org/)
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](https://opensource.org/licenses/MIT)

A tiny, dependency-free Ruby library for writing **soft-fail, composable
service objects**. A service declares its inputs, validates them, runs its
body, and returns a uniform result that always carries either a value plus
warnings or a list of errors — it never raises for expected failures.

## Installation

```sh
bundle add assistant
```

Or without Bundler:

```sh
gem install assistant
```

Ruby `>= 3.4` is required.

## 60-second example

```ruby
require 'assistant'

class CreateUser < Assistant::Service
  input :email, type: String,  required: true
  input :name,  type: String,  required: true
  input :age,   type: Integer, allow_nil: true, default: nil

  def validate
    return if email.include?('@')

    log_item_error(source: :validate, detail: :email, message: 'must contain @')
  end

  def execute
    log_item_warning(source: :execute, detail: :age, message: 'age missing') if age.nil?

    User.create!(email:, name:, age:)
  end
end

CreateUser.run(email: 'ada@example.com', name: 'Ada')
# => { result: #<User …>, status: :with_warnings, warnings: [#<Assistant::LogItem …>] }

CreateUser.run(email: 'nope', name: 'Ada')
# => { errors: [#<Assistant::LogItem …>], result: nil, status: :with_errors }
```

The result hash is always one of two shapes:

```ruby
# Success — status is :ok or :with_warnings
{ result: <Object>, status: :ok | :with_warnings, warnings: Array<Assistant::LogItem> }

# Failure — any error was logged before or during execute
{ errors: Array<Assistant::LogItem>, result: nil, status: :with_errors }
```

Use `#success?`, `#failure?`, and `#status` on a service instance, or
pattern-match the hash returned by `.run` directly.

## Why another service-object gem?

- **No runtime dependencies.** `assistant` is one require away; it does not
  pull in ActiveSupport, dry-rb, or anything else. It runs in plain Ruby,
  Rails, Hanami, Sidekiq workers, and Rake tasks alike.
- **Soft-fail by design.** Validation problems and recoverable failures are
  surfaced as `LogItem`s on the result, not exceptions. Callers
  pattern-match a hash; they don't write `rescue` blocks for expected
  outcomes.
- **Tiny, frozen surface.** The public API documented in
  [`docs/v1/01-api-surface.md`](docs/v1/01-api-surface.md) is everything
  there is. No DSL gymnastics, no plug-in registry, no opinionated
  serialization. Compose services with the plain `#call_service` primitive.

Compared to [Interactor](https://github.com/collectiveidea/interactor) and
[dry-transaction](https://dry-rb.org/gems/dry-transaction/), `assistant`
keeps a single result shape regardless of success or failure, distinguishes
warnings from errors at the log-item level, and ships RBS signatures plus
a per-class generator (`bin/assistant-rbs`) out of the box.

## Documentation

- **API reference** — [`docs/v1/01-api-surface.md`](docs/v1/01-api-surface.md)
  enumerates every public symbol with its stability label.
- **Feature catalogue and rationale** —
  [`docs/v1/02-features.md`](docs/v1/02-features.md).
- **Upgrading from 0.x** —
  [`docs/v1/06-migration-0x-to-1.md`](docs/v1/06-migration-0x-to-1.md).
- **Deprecations** — [`docs/deprecations.md`](docs/deprecations.md).
- **Runnable sample** — [`examples/greeter.rb`](examples/greeter.rb).
- **Changelog** — [`CHANGELOG.md`](CHANGELOG.md).

Longer user-facing guides (`docs/getting-started.md`,
`docs/guides/*.md`) are tracked in
[`docs/v1/03-documentation.md`](docs/v1/03-documentation.md) and land in
follow-up PRs.

## Roadmap

The plan for the 1.0 release lives under
[`docs/v1/`](docs/v1/README.md). Every "must" item is shipped; remaining
work is documentation and release-checklist tasks.

## Development

```sh
bin/setup                                  # install dependencies
bundle exec rake test                      # Minitest
bundle exec rubocop                        # style
bundle exec steep check --jobs=1           # type-check RBS signatures
bin/console                                # IRB session with the gem loaded
```

To install the gem locally for ad-hoc experimentation:

```sh
bundle exec rake install
```

## Contributing

Bug reports and pull requests are welcome at
<https://github.com/ramongr/assistant>. This project is intended to be a
safe, welcoming space for collaboration, and contributors are expected to
adhere to the [Contributor Covenant](http://contributor-covenant.org) code
of conduct.

## License

The gem is released under the terms of the
[MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Assistant project's codebases, issue trackers,
chat rooms, and mailing lists is expected to follow the
[code of conduct](https://github.com/ramongr/assistant/blob/main/CODE_OF_CONDUCT.md).

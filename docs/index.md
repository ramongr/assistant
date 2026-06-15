---
title: Home
layout: home
nav_order: 0
permalink: /
---

# Assistant

**Tiny, dependency-free soft-fail service objects for Ruby.**

[![Gem Version](https://badge.fury.io/rb/assistant.svg)](https://rubygems.org/gems/assistant)
[![CI](https://github.com/ramongr/assistant/actions/workflows/ci.yml/badge.svg)](https://github.com/ramongr/assistant/actions/workflows/ci.yml)

Assistant lets you write service objects that **never raise for expected
failures**. A service declares its inputs, validates them, runs its body, and
returns a uniform result hash that always carries either a value plus
warnings or a list of errors. Ships with RBS signatures, a 1.0-frozen public
API, and zero runtime gem dependencies.

## Install

```ruby
# Gemfile
gem 'assistant', '~> 1.0'
```

```sh
bundle install
```

Ruby 3.4 or newer is required.

## The 60-second example

```ruby
require 'assistant'

class CreateUser < Assistant::Service
  input :email, type: String, required: true
  input :name,  type: String, default: 'Anonymous'

  def execute
    log_item_info(source: :create_user, detail: :persisted, message: "saved #{email}")
    User.create!(email: email, name: name)
  end
end

case CreateUser.run(email: 'me@example.com')
in { result:, status: :ok }
  result
in { errors:, status: :with_errors }
  errors.map(&:item)
end
```

## Where to next

- **[Getting started](getting-started.md)** — walk through your first
  service end-to-end.
- **[Guides](guides/inputs.md)** — DSL deep-dives, one page per concern.
- **[API reference](api-reference.md)** — every Frozen symbol, deep-link
  friendly.
- **[Examples](examples/index.md)** — runnable patterns (Rails, CLI,
  Sidekiq, composition, callbacks, instrumentation, RBS).
- **[Roadmap](roadmap.md)** — what's planned, what shipped.
- **[Changelog](changelog.md)** — full release history.

Source on [GitHub](https://github.com/ramongr/assistant).

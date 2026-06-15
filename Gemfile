# frozen_string_literal: true

source 'https://rubygems.org'

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

# Specify your gem's dependencies in assistant.gemspec
gemspec

# Documentation site (GitHub Pages) toolchain. Optional so regular
# contributors don't pull Jekyll on every `bundle install`. CI's Docs
# workflow installs this group via `BUNDLE_WITH=docs`. See
# `docs/v1/08-github-pages.md` and `Rakefile`'s `docs:*` tasks.
group :docs, optional: true do
  gem 'jekyll', '~> 4.3'
  gem 'jekyll-relative-links', '~> 0.7'
  gem 'just-the-docs', '~> 0.10'
end

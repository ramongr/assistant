# frozen_string_literal: true

source 'https://rubygems.org'

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

# Specify your gem's dependencies in assistant.gemspec
gemspec

# WEBrick is no longer a default gem in Ruby 3.0+. It's a stdlib gem
# used only by `rake docs:serve` to mount the Docsify SPA at
# `/assistant/` with a 404 fallback (history-mode routing). Not in
# `gemspec` because the `runtime-deps` CI gate keeps the gem itself
# dependency-free.
gem 'webrick', '~> 1.8'

#!/usr/bin/env ruby
# frozen_string_literal: true

# `examples/cli_handler/` runnable CLI. Drives the service in
# `create_user.rb` from `OptionParser` and derives the process exit
# code from the result hash's `:status`. Mirrors the script shown
# verbatim in `docs/examples/cli-handler.md`.
#
# Top-level `CreateUser` is aliased to the namespaced
# `CliHandlerExample::CreateUser` so the body of the script reads
# exactly like the docs snippet.

# Require order intentionally matches the docs snippet
# (`stdlib`, `assistant`, `require_relative`) rather than alphabetical.
require 'optparse'
require 'assistant' # rubocop:disable Style/RequireOrder
require_relative 'create_user'

CreateUser = CliHandlerExample::CreateUser unless defined?(CreateUser)

options = {}
OptionParser.new do |opts|
  opts.banner = 'Usage: create_user --email EMAIL --name NAME'
  opts.on('-eEMAIL', '--email=EMAIL') { |v| options[:email] = v }
  opts.on('-nNAME',  '--name=NAME')   { |v| options[:name]  = v }
end.parse!

case CreateUser.run(**options)
in { result:, status: :ok }
  warn "ok: #{result.inspect}"
  exit 0
in { result:, status: :with_warnings, warnings: }
  warn "ok (with warnings): #{result.inspect}"
  warnings.each { |w| warn "  warning: #{w.message}" }
  exit 0
in { errors:, status: :with_errors }
  errors.each { |e| warn "error: #{e.message}" }
  exit 1
end

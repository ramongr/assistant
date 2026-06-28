# frozen_string_literal: true

# Predeclare the namespace shells that multi-segment files
# (`module Assistant::Refinements::StringBlankness`, etc.) need to exist
# before they load, and declare the M-S3 instrumentation notifier
# accessor. Two sibling submodules in one wrapper avoid the
# `Style/CompactModuleNesting` single-child collapse trigger.
module Assistant
  # M-S3: frozen no-op default notifier. Identity-compared by
  # `Assistant.notifier=` so callers can detect the unconfigured state
  # if they ever need to. See docs/v1/index.md (M-S3) and
  # docs/v1/index.md.
  DEFAULT_NOTIFIER = ->(_event, _payload) {}
  DEFAULT_NOTIFIER.freeze

  # Namespace for the InputBuilder DSL and its submodules. Populated by
  # `lib/assistant/input_builder*.rb`.
  module InputBuilder; end

  # Namespace for refinements bundled with the gem (`Refinements::*`).
  module Refinements; end

  @notifier = DEFAULT_NOTIFIER

  class << self
    # Reader for the configured instrumentation callable. Always returns
    # a callable; returns `DEFAULT_NOTIFIER` when never assigned or when
    # explicitly reset with `Assistant.notifier = nil`.
    attr_reader :notifier

    # Writer for the instrumentation callable. Accepts any object
    # responding to `#call(event, payload)`, or `nil` to reset to the
    # built-in no-op default. Anything else raises `ArgumentError`
    # immediately so misconfiguration surfaces at boot rather than at
    # the first service run.
    def notifier=(callable)
      @notifier =
        if callable.nil?
          DEFAULT_NOTIFIER
        elsif callable.respond_to?(:call)
          callable
        else
          raise ArgumentError,
                "Assistant.notifier= expected nil or an object responding to #call, got #{callable.inspect}"
        end
    end
  end
end

# Core building blocks for the Assistant gem. Listed alphabetically so the
# top-level entry point exposes every public constant after a bare
# `require "assistant"` (M6).
require 'assistant/execute_callbacks'
require 'assistant/input_builder'
require 'assistant/log_item'
require 'assistant/log_list'
require 'assistant/refinements/string_blankness'
require 'assistant/service'
require 'assistant/version'

# frozen_string_literal: true

# Predeclare the namespace shells that multi-segment files
# (`module Assistant::Refinements::StringBlankness`, etc.) need to exist
# before they load. Two sibling modules in one wrapper avoid the
# `Style/CompactModuleNesting` single-child collapse trigger.
module Assistant
  # Namespace for the InputBuilder DSL and its submodules. Populated by
  # `lib/assistant/input_builder*.rb`.
  module InputBuilder; end

  # Namespace for refinements bundled with the gem (`Refinements::*`).
  module Refinements; end
end

# Core building blocks for the Assistant gem. Listed alphabetically so the
# top-level entry point exposes every public constant after a bare
# `require "assistant"` (M6).
require 'assistant/input_builder'
require 'assistant/log_item'
require 'assistant/log_list'
require 'assistant/refinements/string_blankness'
require 'assistant/service'
require 'assistant/version'

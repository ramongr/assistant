# frozen_string_literal: true

# Core building blocks for the Assistant gem. Listed alphabetically so the
# top-level entry point exposes every public constant after a bare
# `require "assistant"` (M6).
require 'assistant/input_builder'
require 'assistant/log_item'
require 'assistant/log_list'
require 'assistant/refinements/string_blankness'
require 'assistant/service'
require 'assistant/version'

# Main Assistant lib entry point
module Assistant
end

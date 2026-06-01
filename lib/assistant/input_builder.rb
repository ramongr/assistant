# frozen_string_literal: true

# Umbrella for the input DSL. Each submodule owns one cohesive
# responsibility; this file wires them into a single `Assistant::InputBuilder`
# module that `Service` extends. (M13, v1 plan)
require 'assistant/input_builder/accessors'
require 'assistant/input_builder/default_option'
require 'assistant/input_builder/dsl'
require 'assistant/input_builder/optional_option'
require 'assistant/input_builder/registry'
require 'assistant/input_builder/require_validator'
require 'assistant/input_builder/type_validator'

# Declarative input DSL for `Assistant::Service` subclasses. `#input`
# registers a definition and generates the per-input reader, `?`-checker,
# type validator, and (when `required:` is set) requirement validator(s).
# Behaviour is unchanged from pre-M13; the umbrella only re-exports the
# submodule methods. See the per-submodule files for the specific concern
# each owns.
module Assistant::InputBuilder
  include Registry
  include DefaultOption
  include OptionalOption
  include Accessors
  include RequireValidator
  include TypeValidator
  include Dsl
end

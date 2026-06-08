# frozen_string_literal: true

# Per-class registry of input definitions. Each Service subclass gets its
# own hash keyed by attribute name with the original keyword options
# frozen for introspection (used by Service#initialize for M1 defaulting
# and by the M11 RBS generator).
module Assistant::InputBuilder::Registry
  def input_definitions
    @input_definitions ||= {}
  end

  def register_input_definition(name:, type:, options:)
    input_definitions[name] = { type:, **options }.freeze
  end
end

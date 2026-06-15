# frozen_string_literal: true

# Per-class registry of input definitions. Each Service subclass gets its
# own hash keyed by attribute name with the original keyword options
# frozen for introspection (used by Service#initialize for M1 defaulting
# and by the M11 RBS generator).
module Assistant::InputBuilder::Registry
  # Per-class hash of input definitions, keyed by attribute name.
  # Values are frozen `{ type:, **options }` hashes. Read by
  # `Service#initialize` (M1 defaulting), by `Service#input_snapshot`
  # (M-S4), and by the M11 RBS generator.
  #
  # @return [Hash{Symbol => Hash}]
  def input_definitions
    @input_definitions ||= {}
  end

  # Register or replace an input definition.
  #
  # @param name    [Symbol] input name
  # @param type    [Class, Array<Class>] declared type(s)
  # @param options [Hash]   remaining `#input` keyword options
  # @return [Hash] the frozen definition entry just stored
  def register_input_definition(name:, type:, options:)
    input_definitions[name] = { type:, **options }.freeze
  end
end

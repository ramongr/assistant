# frozen_string_literal: true

module Assistant
  module InputBuilder
    # Per-class registry of input definitions. Each Service subclass gets its
    # own hash keyed by attribute name with the original keyword options
    # frozen for introspection (used by Service#initialize for M1 defaulting
    # and by the M11 RBS generator).
    module Registry
      def input_definitions
        @input_definitions ||= {}
      end

      def register_input_definition(attr_name, type, options)
        input_definitions[attr_name] = { type:, **options }.freeze
      end
    end
  end
end

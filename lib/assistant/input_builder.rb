# frozen_string_literal: true

require 'assistant/refinements/string_blankness'

module Assistant
  # This module has the building blocks for the input validation.
  # The building blocks of listing inputs with the #input and #inputs methods
  # and the building blocks of validating inputs with the methods that are called within those methods.
  module InputBuilder
    using Assistant::Refinements::StringBlankness

    # Per-class registry of input definitions. Each Service subclass gets its own
    # hash, keyed by attribute name, with the original keyword options frozen for
    # introspection (used by Service#initialize for defaulting, M1).
    def input_definitions
      @input_definitions ||= {}
    end

    # Lists all inputs that have the same type and options.
    def inputs(attr_names, type:, **)
      attr_names.each do |attr_name|
        input(attr_name, type:, **)
      end
    end

    # Individual input with a specific type or options
    def input(attr_name, type:, **options)
      if options.key?(:default)
        validate_default!(attr_name, options[:default])
        warn_on_mutable_default(attr_name, options[:default])
      end
      register_input_definition(attr_name, type, options)

      # Base Methods
      input_getter_meth(attr_name)
      input_checker_meth(attr_name)

      # Input type validation method, simple and conditional requirement validation methods
      input_type_validator_meth(attr_name, type, **options)
      input_require_validator_meth(attr_name, **options) if options[:required] == true
      input_require_conditional_meth(attr_name, **options) if options[:required] == true && options[:if]
    end

    def register_input_definition(attr_name, type, options)
      input_definitions[attr_name] = { type:, **options }.freeze
    end

    # M1: a default: provider must be either a literal value or a zero-arity
    # Proc/Lambda. Anything else that responds to #call (a Method object, a
    # custom callable) is rejected at class-definition time.
    def validate_default!(attr_name, default)
      if default.is_a?(Proc) && !default.arity.zero? && default.arity != -1
        raise ArgumentError, "default: for input :#{attr_name} must be a zero-arity Proc, got arity #{default.arity}"
      elsif !default.is_a?(Proc) && default.respond_to?(:call)
        raise ArgumentError,
              "default: for input :#{attr_name} must be a literal or a zero-arity Proc, " \
              "not a #{default.class}"
      end
    end

    # M1: warn when a mutable literal default (unfrozen Array/Hash) is used —
    # such a default is shared across every instance of the Service subclass
    # and almost never what the author wants. Frozen literals and Procs are
    # safe and pass silently.
    def warn_on_mutable_default(attr_name, default)
      return unless (default.is_a?(Array) || default.is_a?(Hash)) && !default.frozen?

      Kernel.warn("assistant: input :#{attr_name} has a mutable #{default.class} default; " \
                  'use `default: -> { ... }` to avoid sharing state across instances')
    end

    def input_getter_meth(attr_name)
      define_method(attr_name) do
        @inputs[attr_name]
      end
    end

    def input_checker_meth(attr_name)
      define_method("#{attr_name}?") do
        val = @inputs[attr_name]
        return false if val.nil? || val == false
        return !val.whitespace? if val.is_a?(String)

        val.respond_to?(:empty?) ? !val.empty? : true
      end
    end

    def input_require_validator_meth(attr_name, **options)
      allow_nil = options.fetch(:allow_nil, false) == true

      define_method("valid_require_#{attr_name}?") do |log = true|
        # M2: explicit nil counts as "supplied" when allow_nil: true is set.
        return true if allow_nil && @inputs.key?(attr_name)
        return true if options[:required] == true && send("#{attr_name}?") == true

        log && send(
          :log_item_error_initialize, attr_name:, message: "Service is missing argument with name #{attr_name}"
        )
        false
      end
    end

    def input_require_conditional_meth(attr_name, **options)
      define_method("valid_require_conditional_#{attr_name}?") do
        return false if send("valid_require_#{attr_name}?", false) == false
        return true if options[:if].call(send(attr_name))

        send(
          :log_item_error_initialize,
          attr_name:, message: "Service argument conditional requirement not met properly for #{attr_name}"
        )
        false
      end
    end

    def input_type_validator_meth(attr_name, type, **options)
      allow_nil = options.fetch(:allow_nil, false) == true
      types = Array(type)
      message_builder = type_mismatch_message_builder(attr_name, types)
      body = type_validator_body(attr_name, types, allow_nil, message_builder)

      define_method("valid_type_#{attr_name}?", &body)
    end

    # Builds the Proc body for the per-input valid_type_<name>? method.
    # Extracted to keep input_type_validator_meth under metric limits.
    def type_validator_body(attr_name, types, allow_nil, message_builder)
      lambda do
        value = @inputs[attr_name]
        # M2: when allow_nil: true is set, any supplied key short-circuits
        # the type check (mirrors the require validator's behaviour).
        next true if allow_nil && @inputs.key?(attr_name)
        next true if types.any? { |klass| value.is_a?(klass) }

        send("#{attr_name}?") &&
          send(:log_item_error_initialize, attr_name:, message: message_builder.call(send(attr_name).class))
        false
      end
    end

    # Returns a Proc that, given the actual class of a failing input,
    # produces the error message. Single-type keeps the original 0.1.0
    # wording for back-compat; multi-type uses "is not one of […]". (M3)
    def type_mismatch_message_builder(attr_name, types)
      if types.size == 1
        ->(actual) { "Service argument with name #{attr_name} is not a #{types.first} but #{actual}" }
      else
        ->(actual) { "Service argument with name #{attr_name} is not one of [#{types.join(', ')}] but #{actual}" }
      end
    end
  end
end

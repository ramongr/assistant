# frozen_string_literal: true

require 'assistant/refinements/string_blankness'

module Assistant
  # This module has the building blocks for the input validation.
  # The building blocks of listing inputs with the #input and #inputs methods
  # and the building blocks of validating inputs with the methods that are called within those methods.
  module InputBuilder
    using Assistant::Refinements::StringBlankness

    # Lists all inputs that have the same type and options.
    def inputs(attr_names, type:, **)
      attr_names.each do |attr_name|
        input(attr_name, type:, **)
      end
    end

    # Individual input with a specific type or options
    def input(attr_name, type:, **options)
      # Base Methods
      input_getter_meth(attr_name)
      input_checker_meth(attr_name)

      # Input type validation method, simple and conditional requirement validation methods
      input_type_validator_meth(attr_name, type)
      input_require_validator_meth(attr_name, **options) if options[:required] == true
      input_require_conditional_meth(attr_name, **options) if options[:required] == true && options[:if]
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
      define_method("valid_require_#{attr_name}?") do |log = true|
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

    def input_type_validator_meth(attr_name, type)
      types = Array(type)
      message_builder = type_mismatch_message_builder(attr_name, types)

      define_method("valid_type_#{attr_name}?") do
        return true if types.any? { |klass| @inputs[attr_name].is_a?(klass) }

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

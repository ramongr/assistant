# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext/object'

module Assistant
  # This module has the building blocks for the input validation.
  # The building blocks of listing inputs with the #input and #inputs methods
  # and the building blocks of validating inputs with the methods that are called within those methods.
  module InputBuilder
    # Lists all inputs that have the same type and options.
    def inputs(attr_names, type:, **)
      attr_names.each do |attr_name|
        input(attr_name, type:, **)
      end
    end

    # Individual input with a specific type or options
    def input(attr_name, type:, **options)
      log_builder_meth
      # Base Methods
      input_getter_meth(attr_name)
      input_checker_meth(attr_name)

      # Input type validation method, simple and conditional requirement validation methods
      input_type_validator_meth(attr_name, type)
      input_require_validator_meth(attr_name, **options) if options[:required] == true
      input_require_conditional_meth(attr_name, **options) if options[:required] == true && options[:if].present?
    end

    def input_getter_meth(attr_name)
      define_method(attr_name) do
        @inputs[attr_name]
      end
    end

    def input_checker_meth(attr_name)
      define_method("#{attr_name}?") do
        @inputs[attr_name].present?
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
      define_method("valid_type_#{attr_name}?") do
        return true if @inputs[attr_name].is_a?(type)

        send("#{attr_name}?") &&
          send(
            :log_item_error_initialize,
            attr_name:, message: "Service argument with name #{attr_name} is not a #{type} but #{send(attr_name).class}"
          )
        false
      end
    end

    def log_builder_meth
      define_method(:log_item_error_initialize) do |attr_name:, message:|
        @logs << LogItem.new(detail: attr_name, level: :error, message:, source: :initialize)
      end
    end
  end
end

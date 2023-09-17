# frozen_string_literal: true

require 'active_support'

module Assistant
  # This module has the building blocks for the input validation.
  # The building blocks of listing inputs with the #input and #inputs methods
  # and the building blocks of validating inputs with the methods that are called within those methods.
  module InputValidation
    # Lists all inputs that have the same type and options.
    def inputs(attr_names, type:, **options)
      attr_names.each do |attr_name|
        input(attr_name, type:, **options)
      end
    end

    # Individual input with a specific type or options
    def input(attr_name, type:, **options)
      input_getter(attr_name)

      input_checker(attr_name)

      input_validator(attr_name, type, **options)
    end

    def input_getter(attr_name)
      define_method(attr_name) do
        @inputs[attr_name]
      end
    end

    def input_checker(attr_name)
      define_method("#{attr_name}?") do
        @inputs[attr_name].present?
      end
    end

    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/BlockLength
    def input_validator(attr_name, type, **options)
      define_method("valid_#{attr_name}?") do
        result = true
        # Validation for required inputs
        if (options[:required] == true || options[:required_if].present?) && send("#{attr_name}?") == false
          @logs << LogItem.new(
            detail: attr_name,
            level: :error,
            message: "Service is missing argument with name #{attr_name}",
            source: :initialize
          )
          result = false
        end

        if options[:required_if].present? && send("#{attr_name}?") == true && !options[:required_if].call(send(attr_name))
          @logs << LogItem.new(
            detail: attr_name,
            level: :error,
            message: "Service argument conditional requirement not met properly for #{attr_name}",
            source: :initialize
          )
          result = false
        end

        # Type check validation
        unless @inputs[attr_name].is_a?(type)
          @logs << LogItem.new(
            detail: attr_name,
            level: :error,
            message: "Service argument with name #{attr_name} is not a #{type} but #{send(attr_name).class}",
            source: :initialize
          )
          result = false
        end

        result
      end
      # rubocop:enable Metrics/MethodLength
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/BlockLength
    end
  end
end

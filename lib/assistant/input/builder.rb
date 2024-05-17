# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext/object'
require_relative 'default_value_builder'
require_relative 'get_set_check'
require_relative 'required_attributes'
require_relative 'type_validator'

module Assistant
  module Input
    # This module has the building blocks for the input validation.
    # The building blocks of listing inputs with the #input and #inputs methods
    # and the building blocks of validating inputs with the methods that are called within those methods.
    module Builder
      include DefaultValueBuilder
      include GetSetCheck
      include RequiredAttributes
      include TypeValidator

      def inputs(attr_names, type:, **)
        attr_names.each do |attr_name|
          input(attr_name, type:, **)
        end
      end

      # Individual input with a specific type or options
      def input(attr_name, type:, **options)
        log_builder_meth
        # Base Methods
        build_getter(attr_name)
        set_attribute(attr_name)
        build_check(attr_name)

        default_value_meth(attr_name, type:, **options) if options[:default].to_s.present?
        # Input type validation method, simple and conditional requirement validation methods
        input_type_validator_meth(attr_name, type)
        input_require_validator_meth(attr_name, **options) if options[:required] == true
        input_require_conditional_meth(attr_name, **options) if options[:required] == true && options[:if].present?
      end

      def log_builder_meth
        define_method(:log_item_error_initialize) do |attr_name:, message:|
          @logs << LogItem.new(detail: attr_name, level: :error, message:, source: :initialize)
        end
      end
    end
  end
end

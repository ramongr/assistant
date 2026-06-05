# frozen_string_literal: true

require_relative '../test_helper'

# Structural smoke tests for the InputBuilder umbrella. Per-concern
# behaviour lives under test/assistant/input_builder/. (M13)
module Assistant
  class InputBuilderTest < Minitest::Test
    SUBMODULES = %i[Registry DefaultOption OptionalOption Accessors RequireValidator TypeValidator Dsl].freeze

    SUBMODULES.each do |submod|
      define_method("test_input_builder_includes_#{submod}") do
        assert_includes Assistant::InputBuilder.included_modules, Assistant::InputBuilder.const_get(submod)
      end
    end

    def test_dsl_methods_are_reachable_from_a_fresh_extend
      klass = Class.new { extend Assistant::InputBuilder }

      assert_respond_to klass, :input
      assert_respond_to klass, :inputs
      assert_respond_to klass, :input_definitions
    end

    def test_every_helper_method_is_reachable_from_a_fresh_extend
      # Regression guard for include-order bugs: if a submodule is dropped
      # from the umbrella, this list catches it before a feature test does.
      klass = Class.new { extend Assistant::InputBuilder }
      expected = %i[
        register_input_definition
        process_default_option validate_default! warn_on_mutable_default
        process_optional_option validate_optional! apply_optional_option
        input_getter_meth input_checker_meth
        input_require_validator_meth input_require_conditional_meth
        input_type_validator_meth type_validator_body type_mismatch_message_builder
      ]

      expected.each { |meth| assert_respond_to klass, meth }
    end

    def test_service_can_use_the_dsl_end_to_end
      klass = Class.new(Assistant::Service) do
        input name: :limit, type: Integer, required: true, default: 5
        def execute = limit * 2
      end

      assert_equal 10, klass.run[:result]
      assert_equal 20, klass.run(limit: 10)[:result]
    end

    # M12: hard break. The old positional form of `Service.input`
    # raises `ArgumentError` at class-definition time, so every miss
    # is caught on first load. Ruby phrases the error as
    # "wrong number of arguments (given 1, expected 0; required
    # keywords: name, type)" since the positional `:foo` is an extra
    # argument and `name:` is unsatisfied.
    def test_input_raises_argument_error_when_called_positionally
      err = assert_raises(ArgumentError) do
        Class.new(Assistant::Service) { input :foo, type: String }
      end

      assert_match(/required keyword/, err.message)
      assert_match(/name/, err.message)
    end

    # M12: same hard break for the plural form.
    def test_inputs_raises_argument_error_when_called_positionally
      err = assert_raises(ArgumentError) do
        Class.new(Assistant::Service) { inputs %i[a b], type: String }
      end

      assert_match(/required keyword/, err.message)
      assert_match(/names/, err.message)
    end
  end
end

# frozen_string_literal: true

require_relative '../test_helper'

module Assistant
  class InputBuilderTest < Minitest::Test
    # ---- Base getters / checkers ----

    def test_single_input_defines_getter_and_checker
      klass = Class.new(Assistant::Service) do
        input :one, type: Integer
        def execute = one
      end

      assert_includes klass.instance_methods, :one
      assert_includes klass.instance_methods, :one?
      assert_equal 1, klass.run(one: 1)[:result]
    end

    def test_inputs_plural_declares_getters_and_validators_for_each_name
      klass = Class.new(Assistant::Service) do
        inputs %i[a b c], type: Integer, required: true
        def execute = [a, b, c].sum
      end

      %i[a b c a? b? c?
         valid_type_a? valid_type_b? valid_type_c?
         valid_require_a? valid_require_b? valid_require_c?].each do |meth|
        assert_includes klass.instance_methods, meth
      end
    end

    def test_inputs_plural_errors_when_any_input_is_missing
      klass = Class.new(Assistant::Service) do
        inputs %i[a b c], type: Integer, required: true
        def execute = [a, b, c].sum
      end

      outcome = klass.run(a: 1, c: 3)

      assert_equal :with_errors, outcome[:status]
      assert_includes outcome[:errors].map(&:detail), :b
    end

    def test_inputs_plural_succeeds_with_full_set
      klass = Class.new(Assistant::Service) do
        inputs %i[a b c], type: Integer, required: true
        def execute = [a, b, c].sum
      end

      outcome = klass.run(a: 1, b: 2, c: 3)

      assert_equal 6, outcome[:result]
      assert_equal :ok, outcome[:status]
    end

    # ---- Type validation ----

    def test_type_validator_logs_error_on_mismatch
      klass = Class.new(Assistant::Service) do
        input :one, type: String
        def execute = 'Hello World'
      end

      outcome = klass.run(one: 1)

      refute_empty outcome[:errors]
      assert_equal('Service argument with name one is not a String but Integer', outcome[:errors].first.message)
    end

    def test_type_validator_passes_when_input_absent_and_optional
      klass = Class.new(Assistant::Service) do
        input :one, type: String
        def execute = 'Hello World'
      end

      outcome = klass.run

      assert_equal 'Hello World', outcome[:result]
      assert_nil outcome[:errors]
    end

    # ---- Conditional requirement ----

    def test_conditional_requirement_errors_when_missing
      klass = Class.new(Assistant::Service) do
        input :token, type: String, required: true, if: ->(val) { val.start_with?('sk-') }
        def execute = token
      end

      outcome = klass.run

      assert_equal :with_errors, outcome[:status]
      assert_includes outcome[:errors].map(&:message), 'Service is missing argument with name token'
    end

    def test_conditional_requirement_errors_when_predicate_false
      klass = Class.new(Assistant::Service) do
        input :token, type: String, required: true, if: ->(val) { val.start_with?('sk-') }
        def execute = token
      end

      outcome = klass.run(token: 'pk-bad')

      assert_equal :with_errors, outcome[:status]
      assert_includes(
        outcome[:errors].map(&:message),
        'Service argument conditional requirement not met properly for token'
      )
    end

    def test_conditional_requirement_succeeds_when_predicate_true
      klass = Class.new(Assistant::Service) do
        input :token, type: String, required: true, if: ->(val) { val.start_with?('sk-') }
        def execute = token
      end

      outcome = klass.run(token: 'sk-ok')

      assert_equal 'sk-ok', outcome[:result]
      assert_equal :ok, outcome[:status]
    end
  end
end

# frozen_string_literal: true

require_relative '../../test_helper'

module Assistant
  module InputBuilder
    class TypeValidatorTest < Minitest::Test
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

      def test_single_type_error_message_format_is_unchanged
        # Back-compat: single-type stays "is not a X but Y" (no brackets).
        klass = Class.new(Assistant::Service) do
          input :one, type: String
          def execute = one
        end

        outcome = klass.run(one: 1)

        assert_equal('Service argument with name one is not a String but Integer', outcome[:errors].first.message)
      end

      # ---- allow_nil: (M2) — paths through the type validator ----

      def test_allow_nil_false_without_required_silently_accepts_nil_back_compat
        # Pre-M2 behaviour: an explicit nil on an optional input produces no error.
        klass = Class.new(Assistant::Service) do
          input :note, type: String
          def execute = :ok
        end

        outcome = klass.run(note: nil)

        assert_equal :ok, outcome[:result]
        assert_equal :ok, outcome[:status]
        assert_nil outcome[:errors]
      end

      def test_allow_nil_true_explicitly_accepts_nil_on_type_check
        klass = Class.new(Assistant::Service) do
          input :note, type: String, allow_nil: true
          def execute = note
        end

        outcome = klass.run(note: nil)

        assert_equal :ok, outcome[:status]
        assert_nil outcome[:result]
        service = klass.new(note: nil)

        assert service.send(:valid_type_note?)
      end

      def test_allow_nil_true_short_circuits_type_check_for_any_supplied_value
        # M2: allow_nil: true means "if the key was supplied, accept it" —
        # this turns off type-checking for that input, mirroring the
        # behaviour of the require validator.
        klass = Class.new(Assistant::Service) do
          input :note, type: String, allow_nil: true
          def execute = note
        end

        outcome = klass.run(note: 42)

        assert_equal :ok, outcome[:status]
        assert_equal 42, outcome[:result]
        assert_nil outcome[:errors]
      end

      # ---- Multi-type (M3) ----

      def test_multi_type_accepts_first_member_type
        klass = Class.new(Assistant::Service) do
          input :amount, type: [Integer, Float]
          def execute = amount
        end

        outcome = klass.run(amount: 1)

        assert_equal 1, outcome[:result]
        assert_equal :ok, outcome[:status]
      end

      def test_multi_type_accepts_second_member_type
        klass = Class.new(Assistant::Service) do
          input :amount, type: [Integer, Float]
          def execute = amount
        end

        outcome = klass.run(amount: 1.5)

        assert_in_delta 1.5, outcome[:result]
        assert_equal :ok, outcome[:status]
      end

      def test_multi_type_logs_error_with_union_message_on_non_member
        klass = Class.new(Assistant::Service) do
          input :amount, type: [Integer, Float]
          def execute = amount
        end

        outcome = klass.run(amount: 'three')

        assert_equal :with_errors, outcome[:status]
        assert_equal(
          'Service argument with name amount is not one of [Integer, Float] but String',
          outcome[:errors].first.message
        )
      end

      def test_multi_type_passes_when_input_absent_and_optional
        klass = Class.new(Assistant::Service) do
          input :amount, type: [Integer, Float]
          def execute = :ok
        end

        outcome = klass.run

        assert_equal :ok, outcome[:result]
        assert_nil outcome[:errors]
      end

      # ---- TypeValidator helpers in isolation ----

      def test_type_mismatch_message_builder_single_type
        bare = Class.new { extend Assistant::InputBuilder::TypeValidator }
        msg  = bare.type_mismatch_message_builder(:limit, [Integer]).call(String)

        assert_equal 'Service argument with name limit is not a Integer but String', msg
      end

      def test_type_mismatch_message_builder_multi_type
        bare = Class.new { extend Assistant::InputBuilder::TypeValidator }
        msg  = bare.type_mismatch_message_builder(:amount, [Integer, Float]).call(String)

        assert_equal 'Service argument with name amount is not one of [Integer, Float] but String', msg
      end
    end
  end
end

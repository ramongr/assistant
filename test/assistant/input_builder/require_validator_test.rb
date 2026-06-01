# frozen_string_literal: true

require_relative '../../test_helper'

module Assistant
  module InputBuilder
    class RequireValidatorTest < Minitest::Test
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

      # ---- allow_nil: (M2) — paths through the require validator ----

      def test_allow_nil_true_with_required_accepts_nil_without_error
        klass = Class.new(Assistant::Service) do
          input :note, type: String, required: true, allow_nil: true
          def execute = note
        end

        outcome = klass.run(note: nil)

        assert_equal :ok, outcome[:status]
        assert_nil outcome[:errors]
      end

      def test_allow_nil_false_with_required_treats_nil_as_missing
        klass = Class.new(Assistant::Service) do
          input :note, type: String, required: true
          def execute = note
        end

        outcome = klass.run(note: nil)

        assert_equal :with_errors, outcome[:status]
        assert_includes outcome[:errors].map(&:message), 'Service is missing argument with name note'
      end

      # ---- RequireValidator helpers in isolation ----

      def test_require_validator_can_be_included_in_isolation
        klass = Class.new(Assistant::Service) do
          extend Assistant::InputBuilder::RequireValidator
          extend Assistant::InputBuilder::Accessors

          input_getter_meth(:foo)
          input_checker_meth(:foo)
          input_require_validator_meth(:foo, required: true)
        end

        assert_includes klass.instance_methods, :valid_require_foo?
      end
    end
  end
end

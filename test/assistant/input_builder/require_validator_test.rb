# frozen_string_literal: true

require_relative '../../test_helper'

module Assistant::InputBuilder
  class RequireValidatorTest < Minitest::Test
    include TestHelpers::IoCapture

    def setup
      # Reset the per-call-site dedupe set so each test starts from a
      # clean slate; otherwise the order tests run in would decide
      # which one observes the first warn.
      Assistant::InputBuilder::RequireValidator.__reset_deprecation_warnings__
    end
    # ---- Conditional requirement ----

    def test_conditional_requirement_errors_when_missing
      klass = Class.new(Assistant::Service) do
        input name: :token, type: String, required: true, if: ->(val) { val.start_with?('sk-') }
        def execute = token
      end

      outcome = klass.run

      assert_equal :with_errors, outcome[:status]
      assert_includes outcome[:errors].map(&:message), 'Service is missing argument with name token'
    end

    def test_conditional_requirement_errors_when_predicate_false
      klass = Class.new(Assistant::Service) do
        input name: :token, type: String, required: true, if: ->(val) { val.start_with?('sk-') }
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
        input name: :token, type: String, required: true, if: ->(val) { val.start_with?('sk-') }
        def execute = token
      end

      outcome = klass.run(token: 'sk-ok')

      assert_equal 'sk-ok', outcome[:result]
      assert_equal :ok, outcome[:status]
    end

    # ---- allow_nil: (M2) — paths through the require validator ----

    def test_allow_nil_true_with_required_accepts_nil_without_error
      klass = Class.new(Assistant::Service) do
        input name: :note, type: String, required: true, allow_nil: true
        def execute = note
      end

      outcome = klass.run(note: nil)

      assert_equal :ok, outcome[:status]
      assert_nil outcome[:errors]
    end

    def test_allow_nil_false_with_required_treats_nil_as_missing
      klass = Class.new(Assistant::Service) do
        input name: :note, type: String, required: true
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

        input_getter_meth(name: :foo)
        input_checker_meth(name: :foo)
        input_require_validator_meth(name: :foo, required: true)
      end

      assert_includes klass.instance_methods, :valid_required_foo?
    end

    # ---- M9: canonical `valid_required_*?` names ----

    def test_required_input_generates_canonical_required_predicate
      klass = Class.new(Assistant::Service) do
        input name: :email, type: String, required: true
      end

      assert_includes klass.instance_methods, :valid_required_email?
    end

    def test_required_conditional_input_generates_canonical_conditional_predicate
      klass = Class.new(Assistant::Service) do
        input name: :token, type: String, required: true, if: ->(v) { v.start_with?('sk-') }
      end

      assert_includes klass.instance_methods, :valid_required_conditional_token?
    end

    def test_optional_input_generates_neither_canonical_nor_deprecated_predicate
      klass = Class.new(Assistant::Service) do
        input name: :nickname, type: String
      end

      refute_includes klass.instance_methods, :valid_required_nickname?
      refute_includes klass.instance_methods, :valid_require_nickname?
    end

    # ---- M9: deprecated `valid_require_*?` aliases ----

    def test_deprecated_alias_is_still_generated_alongside_canonical
      klass = Class.new(Assistant::Service) do
        input name: :email, type: String, required: true
      end

      assert_includes klass.instance_methods, :valid_require_email?
      assert_includes klass.instance_methods, :valid_required_email?
    end

    def test_deprecated_alias_returns_the_same_value_as_canonical
      klass = Class.new(Assistant::Service) do
        input name: :email, type: String, required: true
      end

      missing = klass.new

      capture_io_warn do
        assert_equal missing.valid_required_email?(false), missing.valid_require_email?(false)
      end

      present = klass.new(email: 'x@y')

      capture_io_warn do
        assert_equal present.valid_required_email?, present.valid_require_email?
      end
    end

    def test_deprecated_alias_warns_once_per_call_site_with_canonical_pointer
      klass = Class.new(Assistant::Service) do
        input name: :email, type: String, required: true
      end
      instance = klass.new(email: 'x@y')

      output = capture_io_warn do
        3.times { instance.valid_require_email? } # same call site -> one warn
      end

      assert_equal 1, output.scan('deprecated').size, "got: #{output.inspect}"
      assert_match(/valid_require_email\?/, output)
      assert_match(/valid_required_email\?/, output)
      assert_match(/removed in assistant 2\.0/, output)
    end

    def test_deprecated_alias_warns_again_from_a_distinct_call_site
      klass = Class.new(Assistant::Service) do
        input name: :email, type: String, required: true
      end
      instance = klass.new(email: 'x@y')

      output = capture_io_warn do
        instance.valid_require_email?
        instance.valid_require_email?
      end

      assert_equal 2, output.scan('deprecated').size, "got: #{output.inspect}"
    end

    def test_deprecated_conditional_alias_warns_and_delegates
      klass = Class.new(Assistant::Service) do
        input name: :token, type: String, required: true, if: ->(v) { v.start_with?('sk-') }
      end
      instance = klass.new(token: 'sk-ok')

      output = capture_io_warn do
        assert_equal instance.valid_required_conditional_token?, instance.valid_require_conditional_token?
      end

      assert_match(/valid_require_conditional_token\?/, output)
      assert_match(/valid_required_conditional_token\?/, output)
    end

    def test_service_run_does_not_emit_deprecation_warnings_for_internal_validation
      klass = Class.new(Assistant::Service) do
        input name: :email, type: String, required: true
        input name: :token, type: String, required: true, if: ->(v) { v.start_with?('sk-') }
        def execute = :ok
      end

      output = capture_io_warn { klass.run(email: 'x@y', token: 'sk-ok') }

      refute_match(/deprecated/, output)
    end
  end
end

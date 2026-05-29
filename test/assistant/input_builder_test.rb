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

    # ---- default: (M1) ----

    def test_default_literal_applies_when_key_absent
      klass = Class.new(Assistant::Service) do
        input :limit, type: Integer, default: 10
        def execute = limit
      end

      assert_equal 10, klass.run[:result]
    end

    def test_default_does_not_override_caller_supplied_value
      klass = Class.new(Assistant::Service) do
        input :limit, type: Integer, default: 10
        def execute = limit
      end

      assert_equal 25, klass.run(limit: 25)[:result]
    end

    def test_default_applies_when_caller_passes_explicit_nil
      klass = Class.new(Assistant::Service) do
        input :limit, type: Integer, default: 10
        def execute = limit
      end

      assert_equal 10, klass.run(limit: nil)[:result]
    end

    def test_default_does_not_fire_when_allow_nil_input_is_explicitly_nil
      # M1 + M2 interaction: allow_nil: true means the caller's nil is a
      # legitimate value, so the default must NOT clobber it.
      klass = Class.new(Assistant::Service) do
        input :note, type: String, default: 'fallback', allow_nil: true
        def execute = note
      end

      outcome = klass.run(note: nil)

      assert_equal :ok, outcome[:status]
      assert_nil outcome[:result]
    end

    def test_default_still_fires_for_allow_nil_input_when_key_absent
      klass = Class.new(Assistant::Service) do
        input :note, type: String, default: 'fallback', allow_nil: true
        def execute = note
      end

      assert_equal 'fallback', klass.run[:result]
    end

    def test_default_proc_is_called_per_instance
      counter = 0
      provider = -> { counter += 1 }
      klass = Class.new(Assistant::Service) do
        input :seq, type: Integer, default: provider
        def execute = seq
      end

      assert_equal 1, klass.run[:result]
      assert_equal 2, klass.run[:result]
    end

    def test_default_satisfies_required
      klass = Class.new(Assistant::Service) do
        input :name, type: String, required: true, default: 'anon'
        def execute = name
      end

      outcome = klass.run

      assert_equal 'anon', outcome[:result]
      assert_equal :ok, outcome[:status]
    end

    def test_default_is_type_validated
      klass = Class.new(Assistant::Service) do
        input :limit, type: Integer, default: 'oops'
        def execute = limit
      end

      outcome = klass.run

      assert_equal :with_errors, outcome[:status]
      assert_includes(outcome[:errors].map(&:message), 'Service argument with name limit is not a Integer but String')
    end

    def test_default_value_is_visible_to_if_predicate
      klass = Class.new(Assistant::Service) do
        input :token, type: String, required: true, default: 'sk-default', if: ->(val) { val.start_with?('sk-') }
        def execute = token
      end

      outcome = klass.run

      assert_equal 'sk-default', outcome[:result]
      assert_equal :ok, outcome[:status]
    end

    def test_default_proc_with_arity_greater_than_zero_raises_at_class_definition
      error = assert_raises(ArgumentError) do
        Class.new(Assistant::Service) do
          input :limit, type: Integer, default: ->(x) { x + 1 }
        end
      end

      assert_match(/default: for input :limit must be a zero-arity Proc/, error.message)
    end

    def test_default_method_object_raises_at_class_definition
      error = assert_raises(ArgumentError) do
        Class.new(Assistant::Service) do
          input :name, type: String, default: 'hi'.method(:upcase)
        end
      end

      assert_match(/default: for input :name must be a literal or a zero-arity Proc/, error.message)
    end

    def test_mutable_array_default_warns_at_class_definition
      output = capture_io_warn do
        Class.new(Assistant::Service) do
          input :items, type: Array, default: []
        end
      end

      assert_match(/input :items has a mutable Array default/, output)
    end

    def test_frozen_array_default_does_not_warn
      output = capture_io_warn do
        Class.new(Assistant::Service) do
          input :items, type: Array, default: [].freeze
        end
      end

      assert_empty output
    end

    def test_proc_default_returning_mutable_array_does_not_warn
      output = capture_io_warn do
        Class.new(Assistant::Service) do
          input :items, type: Array, default: -> { [] }
        end
      end

      assert_empty output
    end

    def test_input_definitions_exposes_default_provider
      provider = -> { 42 }
      klass = Class.new(Assistant::Service) do
        input :limit, type: Integer, default: provider
      end

      assert_same provider, klass.input_definitions[:limit][:default]
    end

    # ---- allow_nil: (M2) ----

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

    def test_single_type_error_message_format_is_unchanged
      # Back-compat: single-type stays "is not a X but Y" (no brackets).
      klass = Class.new(Assistant::Service) do
        input :one, type: String
        def execute = one
      end

      outcome = klass.run(one: 1)

      assert_equal('Service argument with name one is not a String but Integer', outcome[:errors].first.message)
    end

    # ---- optional: (M7) ----

    def test_optional_true_runs_cleanly_when_key_absent
      klass = Class.new(Assistant::Service) do
        input :nickname, type: String, optional: true
        def execute = nickname || :missing
      end

      outcome = klass.run

      assert_equal :missing, outcome[:result]
      assert_equal :ok, outcome[:status]
      assert_nil outcome[:errors]
    end

    def test_optional_true_alone_does_not_generate_require_validator
      klass = Class.new(Assistant::Service) do
        input :nickname, type: String, optional: true
      end

      refute_includes klass.instance_methods, :valid_require_nickname?
    end

    def test_optional_false_is_equivalent_to_required_true
      klass = Class.new(Assistant::Service) do
        input :email, type: String, optional: false
        def execute = email
      end

      assert_includes klass.instance_methods, :valid_require_email?

      outcome = klass.run

      assert_equal :with_errors, outcome[:status]
      assert_includes outcome[:errors].map(&:message), 'Service is missing argument with name email'
    end

    def test_required_true_and_optional_true_together_raise_at_class_definition
      error = assert_raises(ArgumentError) do
        Class.new(Assistant::Service) do
          input :foo, type: String, required: true, optional: true
        end
      end

      assert_match(/input :foo cannot be both required: true and optional: true/, error.message)
    end

    def test_non_boolean_optional_raises_at_class_definition
      error = assert_raises(ArgumentError) do
        Class.new(Assistant::Service) do
          input :foo, type: String, optional: :sometimes
        end
      end

      assert_match(/optional: for input :foo must be true or false/, error.message)
    end

    def test_optional_true_with_default_applies_default_when_key_absent
      klass = Class.new(Assistant::Service) do
        input :limit, type: Integer, optional: true, default: 25
        def execute = limit
      end

      outcome = klass.run

      assert_equal 25, outcome[:result]
      assert_equal :ok, outcome[:status]
    end

    def test_optional_true_with_allow_nil_accepts_explicit_nil
      klass = Class.new(Assistant::Service) do
        input :note, type: String, optional: true, allow_nil: true
        def execute = note
      end

      outcome = klass.run(note: nil)

      assert_equal :ok, outcome[:status]
      assert_nil outcome[:result]
      assert_nil outcome[:errors]
    end

    def test_optional_flag_is_retained_in_input_definitions
      klass = Class.new(Assistant::Service) do
        input :nickname, type: String, optional: true
      end

      assert(klass.input_definitions[:nickname][:optional])
    end

    private

    def capture_io_warn
      original = $stderr
      $stderr = StringIO.new
      yield
      $stderr.string
    ensure
      $stderr = original
    end
  end
end

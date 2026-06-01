# frozen_string_literal: true

require_relative '../../test_helper'

module Assistant::InputBuilder
  class OptionalOptionTest < Minitest::Test
    # ---- Behaviour through Service.input (M7) ----

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

    # ---- OptionalOption helpers in isolation (M7 SRP split) ----

    def test_validate_optional_bang_raises_on_non_boolean
      bare = Class.new { extend Assistant::InputBuilder::OptionalOption }

      error = assert_raises(ArgumentError) do
        bare.validate_optional!(:foo, { optional: :sometimes })
      end

      assert_match(/optional: for input :foo must be true or false/, error.message)
    end

    def test_validate_optional_bang_raises_on_required_optional_contradiction
      bare = Class.new { extend Assistant::InputBuilder::OptionalOption }

      error = assert_raises(ArgumentError) do
        bare.validate_optional!(:foo, { optional: true, required: true })
      end

      assert_match(/cannot be both required: true and optional: true/, error.message)
    end

    def test_validate_optional_bang_returns_nil_on_valid_options
      bare = Class.new { extend Assistant::InputBuilder::OptionalOption }

      assert_nil bare.validate_optional!(:foo, { optional: true })
      assert_nil bare.validate_optional!(:foo, { optional: false })
    end

    def test_apply_optional_option_translates_false_to_required_true
      bare = Class.new { extend Assistant::InputBuilder::OptionalOption }
      result = bare.apply_optional_option({ optional: false, type: String })

      assert(result[:required])
      refute(result[:optional])
    end

    def test_apply_optional_option_leaves_true_untouched
      bare = Class.new { extend Assistant::InputBuilder::OptionalOption }
      input  = { optional: true, type: String }
      result = bare.apply_optional_option(input)

      refute result.key?(:required)
      assert_equal input, result
    end

    def test_apply_optional_option_is_non_mutating
      bare = Class.new { extend Assistant::InputBuilder::OptionalOption }
      input  = { optional: false, type: String }
      before = input.dup

      bare.apply_optional_option(input)

      assert_equal before, input
    end
  end
end

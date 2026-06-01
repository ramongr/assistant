# frozen_string_literal: true

require_relative '../../test_helper'

module Assistant
  module InputBuilder
    class DefaultOptionTest < Minitest::Test
      include TestHelpers::IoCapture

      # ---- Behaviour through Service.input (M1) ----

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

      # ---- DefaultOption helpers in isolation ----

      def test_validate_default_bang_raises_on_non_proc_callable
        bare = Class.new { extend Assistant::InputBuilder::DefaultOption }

        error = assert_raises(ArgumentError) do
          bare.validate_default!(:foo, 'hi'.method(:upcase))
        end

        assert_match(/must be a literal or a zero-arity Proc/, error.message)
      end

      def test_validate_default_bang_raises_on_non_zero_arity_proc
        bare = Class.new { extend Assistant::InputBuilder::DefaultOption }

        error = assert_raises(ArgumentError) do
          bare.validate_default!(:foo, ->(x) { x })
        end

        assert_match(/must be a zero-arity Proc, got arity 1/, error.message)
      end

      def test_validate_default_bang_accepts_literals_and_zero_arity_procs
        bare = Class.new { extend Assistant::InputBuilder::DefaultOption }

        assert_nil bare.validate_default!(:foo, 42)
        assert_nil bare.validate_default!(:foo, 'literal')
        assert_nil bare.validate_default!(:foo, -> { 1 })
        assert_nil bare.validate_default!(:foo, proc { 1 })
      end

      def test_warn_on_mutable_default_is_silent_for_safe_values
        bare = Class.new { extend Assistant::InputBuilder::DefaultOption }

        output = capture_io_warn do
          bare.warn_on_mutable_default(:foo, 42)
          bare.warn_on_mutable_default(:foo, [].freeze)
          bare.warn_on_mutable_default(:foo, {}.freeze)
          bare.warn_on_mutable_default(:foo, -> { [] })
        end

        assert_empty output
      end
    end
  end
end

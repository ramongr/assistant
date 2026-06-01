# frozen_string_literal: true

require_relative '../../test_helper'

module Assistant::InputBuilder
  class DslTest < Minitest::Test
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
  end
end

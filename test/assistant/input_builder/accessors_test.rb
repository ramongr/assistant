# frozen_string_literal: true

require_relative '../../test_helper'

module Assistant::InputBuilder
  class AccessorsTest < Minitest::Test
    def test_single_input_defines_getter_and_checker
      klass = Class.new(Assistant::Service) do
        input name: :one, type: Integer
        def execute = one
      end

      assert_includes klass.instance_methods, :one
      assert_includes klass.instance_methods, :one?
      assert_equal 1, klass.run(one: 1)[:result]
    end

    def test_checker_returns_false_for_whitespace_only_string
      klass = Class.new(Assistant::Service) do
        input name: :note, type: String
        def execute = note? ? note : :blank
      end

      outcome = klass.run(note: "   \t\n")

      assert_equal :blank, outcome[:result]
    end

    def test_checker_returns_true_for_non_blank_string
      klass = Class.new(Assistant::Service) do
        input name: :note, type: String
        def execute = note? ? note : :blank
      end

      outcome = klass.run(note: 'hi')

      assert_equal 'hi', outcome[:result]
    end

    def test_checker_returns_false_for_nil_and_false_values
      klass = Class.new(Assistant::Service) do
        input name: :flag, type: [TrueClass, FalseClass]
        def execute = flag?
      end

      refute klass.run(flag: nil)[:result]
      refute klass.run(flag: false)[:result]
    end

    def test_checker_uses_empty_for_collection_inputs
      klass = Class.new(Assistant::Service) do
        input name: :tags, type: Array
        def execute = tags? ? tags : :empty
      end

      assert_equal :empty,   klass.run(tags: [])[:result]
      assert_equal [:a],     klass.run(tags: [:a])[:result]
    end

    # ---- Accessors helpers in isolation ----

    def test_accessors_can_be_included_in_isolation
      klass = Class.new do
        extend Assistant::InputBuilder::Accessors

        input_getter_meth(name: :val)
        input_checker_meth(name: :val)
        def initialize(val:) = @inputs = { val: }
      end

      instance = klass.new(val: 42)

      assert_equal 42, instance.val
      assert_predicate instance, :val?
    end
  end
end

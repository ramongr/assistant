# frozen_string_literal: true

require_relative '../../test_helper'

module Assistant::InputBuilder
  class RegistryTest < Minitest::Test
    def test_input_definitions_returns_a_fresh_hash_per_class
      a = Class.new { extend Assistant::InputBuilder }
      b = Class.new { extend Assistant::InputBuilder }

      a.input(:foo, type: String)

      assert_equal({ type: String }, a.input_definitions[:foo])
      assert_empty b.input_definitions
    end

    def test_register_input_definition_freezes_the_per_input_options_hash
      klass = Class.new { extend Assistant::InputBuilder }
      klass.input(:foo, type: Integer, required: true)

      assert_predicate klass.input_definitions[:foo], :frozen?
    end

    def test_register_input_definition_records_type_and_options
      klass = Class.new { extend Assistant::InputBuilder }
      klass.input(:limit, type: Integer, required: true, default: 25)

      defn = klass.input_definitions[:limit]

      assert_equal Integer, defn[:type]
      assert(defn[:required])
      assert_equal 25, defn[:default]
    end

    def test_registry_can_be_included_in_isolation
      bare = Class.new { extend Assistant::InputBuilder::Registry }

      assert_empty bare.input_definitions
      bare.register_input_definition(:foo, String, { required: true })

      assert_equal({ type: String, required: true }, bare.input_definitions[:foo])
    end
  end
end

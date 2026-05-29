# frozen_string_literal: true

require_relative 'test_helper'

class AssistantTest < Minitest::Test
  def test_has_a_version_number
    refute_nil Assistant::VERSION
  end

  def test_version_is_a_string
    assert_kind_of String, Assistant::VERSION
  end

  # M6: every core building block must be reachable from a bare `require "assistant"`.
  def test_core_constants_are_loaded
    assert defined?(Assistant::VERSION),     'Assistant::VERSION should be loaded'
    assert defined?(Assistant::LogItem),     'Assistant::LogItem should be loaded'
    assert defined?(Assistant::LogList),     'Assistant::LogList should be loaded'
    assert defined?(Assistant::InputBuilder), 'Assistant::InputBuilder should be loaded'
    assert defined?(Assistant::Service), 'Assistant::Service should be loaded'
    assert defined?(Assistant::Refinements::StringBlankness), 'Assistant::Refinements::StringBlankness should be loaded'
  end
end

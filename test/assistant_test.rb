# frozen_string_literal: true

require_relative 'test_helper'

class AssistantTest < Minitest::Test
  def test_has_a_version_number
    refute_nil Assistant::VERSION
  end

  def test_version_is_a_string
    assert_kind_of String, Assistant::VERSION
  end
end

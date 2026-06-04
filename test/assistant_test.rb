# frozen_string_literal: true

require_relative 'test_helper'

class AssistantTest < Minitest::Test
  # ---- M-S3: instrumentation notifier ----

  def teardown
    Assistant.notifier = nil
    super
  end

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

  def test_notifier_defaults_to_a_callable_no_op
    assert_respond_to Assistant.notifier, :call
    assert_nil Assistant.notifier.call(:service_started, { service_class: Assistant::Service, duration_s: 0.0 })
  end

  def test_notifier_default_constant_is_frozen
    assert_predicate Assistant::DEFAULT_NOTIFIER, :frozen?
  end

  def test_notifier_returns_default_when_never_assigned
    assert_same Assistant::DEFAULT_NOTIFIER, Assistant.notifier
  end

  def test_notifier_setter_accepts_a_proc
    proc_notifier = ->(_event, _payload) {}
    Assistant.notifier = proc_notifier

    assert_same proc_notifier, Assistant.notifier
  end

  def test_notifier_setter_accepts_a_lambda
    lambda_notifier = ->(_event, _payload) {}
    Assistant.notifier = lambda_notifier

    assert_same lambda_notifier, Assistant.notifier
  end

  def test_notifier_setter_accepts_a_method_object
    helper = Object.new
    def helper.record(_event, _payload); end

    Assistant.notifier = helper.method(:record)

    assert_respond_to Assistant.notifier, :call
  end

  def test_notifier_setter_accepts_any_object_responding_to_call
    callable_obj = Object.new
    def callable_obj.call(_event, _payload); end

    Assistant.notifier = callable_obj

    assert_same callable_obj, Assistant.notifier
  end

  def test_notifier_setter_resets_to_default_when_assigned_nil
    Assistant.notifier = ->(_event, _payload) {}
    Assistant.notifier = nil

    assert_same Assistant::DEFAULT_NOTIFIER, Assistant.notifier
  end

  def test_notifier_setter_raises_argument_error_for_non_callable
    assert_raises(ArgumentError) { Assistant.notifier = 42 }
    assert_raises(ArgumentError) { Assistant.notifier = 'not a notifier' }
    assert_raises(ArgumentError) { Assistant.notifier = Object.new }
  end

  def test_notifier_setter_error_message_includes_offending_value
    error = assert_raises(ArgumentError) { Assistant.notifier = :nope }

    assert_match(/respond.*to.*#call/, error.message)
    assert_includes error.message, ':nope'
  end
end

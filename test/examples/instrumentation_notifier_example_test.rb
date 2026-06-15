# frozen_string_literal: true

require 'minitest/autorun'
require_relative 'test_helper'
require File.join(ExampleTestHelpers::EXAMPLES_ROOT, 'instrumentation_notifier/notifier_example')

# Pins the lifecycle event sequence and payload contract documented at
# docs/examples/instrumentation-notifier.md. Every test resets
# `Assistant.notifier` in `ensure` so the gem-wide singleton never
# leaks across the file (or into sibling test suites that depend on
# the default no-op notifier).
class InstrumentationNotifierExampleTest < Minitest::Test
  include TestHelpers::IoCapture

  def teardown
    Assistant.notifier = nil
  end

  def test_happy_path_emits_started_validated_executed_in_order
    captured = InstrumentationNotifierExample::NotifierExample.run

    assert_equal %i[service_started service_validated service_executed], captured[:ok].map(&:first)
  end

  def test_failure_path_emits_started_validated_failed_in_order
    captured = InstrumentationNotifierExample::NotifierExample.run

    assert_equal %i[service_started service_validated service_failed], captured[:failed].map(&:first)
  end

  def test_every_payload_includes_service_class_and_duration_s
    captured = InstrumentationNotifierExample::NotifierExample.run
    payloads = captured[:ok].map(&:last) + captured[:failed].map(&:last)

    assert(payloads.all? { |p| p[:service_class] == InstrumentationNotifierExample::CreateUser })
    assert(payloads.all? { |p| p[:duration_s].is_a?(Float) && p[:duration_s] >= 0 })
  end

  def test_payload_carries_exactly_service_class_and_duration_s
    captured = InstrumentationNotifierExample::NotifierExample.run

    assert_equal %i[service_class duration_s].sort, captured[:ok].first.last.keys.sort
  end

  def test_notifier_exception_is_warn_logged_not_raised
    Assistant.notifier = ->(_event, _payload) { raise 'boom' }
    stderr = capture_io_warn do
      payload = InstrumentationNotifierExample::CreateUser.run(email: 'a@b.com', name: 'Ada')

      assert_equal :ok, payload[:status]
    end

    assert_match(/notifier raised during service_started/, stderr)
  end
end

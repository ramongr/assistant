# frozen_string_literal: true

require 'minitest/autorun'
require_relative 'test_helper'
require File.join(ExampleTestHelpers::EXAMPLES_ROOT, 'execute_callbacks/audited_service')

# Pins the observable log timeline produced by the `before_execute` /
# `around_execute` / `after_execute` hooks registered on
# `ExecuteCallbacksExample::AuditedService`. The around-hook's
# `log_item_info(:timing)` line fires *after* `cont.call` returns, so
# the user-visible order on `service.infos` is
# `:start` → `:timing` → `:finish`. The timing-format test stays
# non-flaky by accepting any non-negative duration that matches
# `<digits>(.<digits>)?ms`.
class ExecuteCallbacksExampleTest < Minitest::Test
  def setup
    @service = ExecuteCallbacksExample::AuditedService.new(user_id: 42)
    @service.run
  end

  def test_emits_three_info_log_items_one_per_hook
    assert_equal 3, @service.infos.size
    assert_equal :ok, @service.status
  end

  def test_hook_emitted_details_appear_in_observable_order
    assert_equal %i[start timing finish], @service.infos.map(&:detail)
  end

  def test_before_and_after_hooks_interpolate_user_id_in_message
    start_log, _timing_log, finish_log = @service.infos

    assert_equal 'user=42', start_log.message
    assert_equal 'user=42', finish_log.message
  end

  def test_around_hook_timing_message_matches_milliseconds_format
    timing_log = @service.infos[1]

    assert_match(/\A\d+(?:\.\d+)?ms\z/, timing_log.message)
  end

  def test_every_hook_log_is_stamped_with_audit_source
    sources = @service.infos.map(&:source)

    assert_equal %i[audit audit audit], sources
  end

  def test_execute_body_still_returns_the_documented_result_hash
    assert_equal({ user_id: 42 }, @service.result)
  end
end

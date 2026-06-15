# frozen_string_literal: true

require 'assistant'

# Companion to docs/examples/execute-callbacks.md.
#
# Shows how `before_execute` / `after_execute` / `around_execute` hooks
# layer around `#execute`: a before-hook records `:start`, an around-hook
# wraps the call to capture wall time as `:timing`, and an after-hook
# records `:finish`. Hooks run in this observable order on the log
# timeline: `:start` -> `:timing` -> `:finish`, because the around-hook's
# log fires *after* `blk.call` returns, which itself happens between the
# before- and after-hooks (see lib/assistant/service.rb#run_execute_with_callbacks).
module ExecuteCallbacksExample
  # A service whose business logic is intentionally trivial so the test
  # can pin the hook-emitted log timeline without flakiness. The real
  # body would live inside `#execute`; here it just echoes the input so
  # downstream callers see a result hash they can pattern-match on.
  class AuditedService < Assistant::Service
    input :user_id, type: Integer, required: true

    before_execute do
      log_item_info(source: :audit, detail: :start, message: "user=#{user_id}")
    end

    after_execute do |_result|
      log_item_info(source: :audit, detail: :finish, message: "user=#{user_id}")
    end

    around_execute do |&blk|
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      inner = blk.call
      elapsed_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1000).round(1)
      log_item_info(source: :audit, detail: :timing, message: "#{elapsed_ms}ms")
      inner
    end

    def execute
      { user_id: }
    end
  end
end

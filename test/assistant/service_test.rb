# frozen_string_literal: true

require_relative '../test_helper'

module Assistant
  class ServiceTest < Minitest::Test
    # ---- M-S3: instrumentation notifier ----
    #
    # Each test resets the notifier in teardown so configuration cannot
    # leak across tests or to AssistantTest.

    include TestHelpers::IoCapture

    def teardown
      Assistant.notifier = nil
      super
    end

    # ---- Base class without arguments ----

    def test_inputs_default_to_empty_hash
      assert_equal({}, Assistant::Service.new.instance_variable_get(:@inputs))
    end

    def test_run_with_no_execute_returns_nil_result
      assert_nil Assistant::Service.new.run[:result]
    end

    def test_run_returns_status_ok_and_no_warnings_by_default
      outcome = Assistant::Service.new.run

      assert_equal :ok, outcome[:status]
      assert_equal [], outcome[:warnings]
    end

    # ---- Subclass overriding execute ----

    def test_subclass_with_overridden_execute_returns_result
      klass = Class.new(Assistant::Service) do
        def execute = true
      end

      outcome = klass.run

      assert outcome[:result]
      assert_equal :ok, outcome[:status]
      assert_equal [], outcome[:warnings]
    end

    # ---- Input declarations ----

    def test_service_with_optional_input_executes_successfully
      klass = Class.new(Assistant::Service) do
        input :one, type: Integer
        def execute = true
      end

      outcome = klass.run

      assert outcome[:result]
      assert_equal :ok, outcome[:status]
    end

    def test_service_with_required_input_missing_returns_errors
      klass = Class.new(Assistant::Service) do
        input :one, type: Integer, required: true
        def execute = true
      end

      outcome = klass.run

      assert_nil outcome[:result]
      assert_equal :with_errors, outcome[:status]
      assert_equal 1, outcome[:errors].size
    end

    def test_service_with_required_string_input_treats_whitespace_as_missing
      klass = Class.new(Assistant::Service) do
        input :name, type: String, required: true
        def execute = true
      end

      outcome = klass.run(name: "   \t\n")

      assert_nil outcome[:result]
      assert_equal :with_errors, outcome[:status]
      assert_equal 1, outcome[:errors].size
    end

    # ---- Custom validate hook ----

    def test_custom_validate_with_error_log_fails
      klass = Class.new(Assistant::Service) do
        input :one, type: Integer
        def validate
          add_log(level: :error, detail: :base, source: :validate, message: 'boom')
        end

        def execute = true
      end

      outcome = klass.run

      assert_nil outcome[:result]
      assert_equal :with_errors, outcome[:status]
    end

    def test_custom_validate_with_warning_log_succeeds_with_warnings
      klass = Class.new(Assistant::Service) do
        input :one, type: Integer
        def validate
          add_log(level: :warning, detail: :base, source: :validate, message: 'heads up')
        end

        def execute = true
      end

      outcome = klass.run

      assert outcome[:result]
      assert_equal :with_warnings, outcome[:status]
      assert_operator outcome[:warnings].size, :>, 0
    end

    # ---- Status / success? / failure? ----

    def test_success_status_when_clean
      service = Class.new(Assistant::Service) do
        def execute = :ok
      end.new
      service.run

      assert_predicate service, :success?
      refute_predicate service, :failure?
      assert_equal :ok, service.status
    end

    def test_status_with_warnings_when_warning_present
      service = Class.new(Assistant::Service) do
        def validate
          add_log(level: :warning, source: :execute, detail: :something, message: 'heads up')
        end

        def execute = :ok
      end.new
      service.run

      assert_predicate service, :success?
      assert_equal :with_warnings, service.status
    end

    def test_failure_when_error_present
      service = Class.new(Assistant::Service) do
        def validate
          add_log(level: :error, source: :execute, detail: :something, message: 'boom')
        end

        def execute = :ok
      end.new
      service.run

      assert_predicate service, :failure?
      refute_predicate service, :success?
    end

    # ---- #result memoization ----

    def test_result_memoizes_execute_call
      calls = 0
      klass = Class.new(Assistant::Service)
      klass.define_method(:execute) { calls += 1 }

      service = klass.new

      assert_equal 1, service.result
      assert_equal 1, service.result
      assert_equal 1, calls
    end

    # ---- #logs reader (M4) ----

    def test_logs_reader_returns_empty_array_on_fresh_service
      assert_equal [], Assistant::Service.new.logs
    end

    def test_logs_reader_returns_all_levels_in_insertion_order
      klass = Class.new(Assistant::Service) do
        def validate
          add_log(level: :info,    source: :validate, detail: :step1, message: 'ok')
          add_log(level: :warning, source: :validate, detail: :step2, message: 'heads up')
          add_log(level: :error,   source: :validate, detail: :step3, message: 'boom')
        end

        def execute = :ok
      end

      service = klass.new
      service.run

      assert_equal 3, service.logs.size
      assert_equal %i[info warning error], service.logs.map(&:level)
    end

    def test_logs_reader_is_union_of_infos_warnings_errors
      klass = Class.new(Assistant::Service) do
        def validate
          add_log(level: :info,    source: :validate, detail: :step1, message: 'ok')
          add_log(level: :warning, source: :validate, detail: :step2, message: 'heads up')
        end

        def execute = :ok
      end

      service = klass.new
      service.run

      assert_equal((service.infos + service.warnings + service.errors).sort_by(&:object_id),
                   service.logs.sort_by(&:object_id))
    end

    def with_recording_notifier
      events = []
      Assistant.notifier = ->(event, payload) { events << [event, payload] }
      events
    end

    def test_successful_run_fires_started_validated_executed_in_order
      events = with_recording_notifier
      klass = Class.new(Assistant::Service) do
        def execute = :ok
      end

      klass.run

      assert_equal %i[service_started service_validated service_executed], events.map(&:first)
    end

    def test_successful_run_does_not_fire_service_failed
      events = with_recording_notifier
      klass = Class.new(Assistant::Service) do
        def execute = :ok
      end

      klass.run

      refute_includes events.map(&:first), :service_failed
    end

    def test_failing_run_fires_started_validated_failed_in_order
      events = with_recording_notifier
      klass = Class.new(Assistant::Service) do
        input :one, type: Integer, required: true
        def execute = true
      end

      klass.run

      assert_equal %i[service_started service_validated service_failed], events.map(&:first)
    end

    def test_failing_run_does_not_fire_service_executed
      events = with_recording_notifier
      klass = Class.new(Assistant::Service) do
        input :one, type: Integer, required: true
        def execute = true
      end

      klass.run

      refute_includes events.map(&:first), :service_executed
    end

    def test_event_payload_includes_service_class_and_duration
      events = with_recording_notifier
      klass = Class.new(Assistant::Service) do
        def execute = :ok
      end

      klass.run

      events.each do |(_event, payload)|
        assert_same klass, payload[:service_class]
        assert_kind_of Float, payload[:duration_s]
        assert_operator payload[:duration_s], :>=, 0.0
      end
    end

    def test_event_duration_is_monotonically_non_decreasing_across_events
      events = with_recording_notifier
      klass = Class.new(Assistant::Service) do
        def execute = :ok
      end

      klass.run

      durations = events.map { |(_event, payload)| payload[:duration_s] }

      assert_equal durations.sort, durations,
                   "expected duration_s to be non-decreasing across events, got #{durations.inspect}"
    end

    def test_notifier_exception_is_captured_and_run_returns_normally
      Assistant.notifier = ->(_event, _payload) { raise 'boom from notifier' }
      klass = Class.new(Assistant::Service) do
        def execute = :ok
      end

      outcome = nil
      stderr = capture_io_warn { outcome = klass.run }

      assert_equal :ok, outcome[:status]
      assert_equal :ok, outcome[:result]
      assert_match(/notifier raised during service_started/, stderr)
    end

    def test_notifier_exception_does_not_block_subsequent_events
      events = []
      first_call = true
      Assistant.notifier = lambda do |event, payload|
        if first_call
          first_call = false
          raise 'boom from notifier'
        end
        events << [event, payload]
      end

      klass = Class.new(Assistant::Service) do
        def execute = :ok
      end

      capture_io_warn { klass.run }

      assert_equal %i[service_validated service_executed], events.map(&:first)
    end

    def test_run_with_default_notifier_is_a_silent_no_op
      klass = Class.new(Assistant::Service) do
        def execute = :ok
      end

      stderr = capture_io_warn { klass.run }

      assert_empty stderr
    end
  end
end

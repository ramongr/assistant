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

    # ---- #run idempotency ----

    def test_run_called_twice_returns_same_payload_object
      klass = Class.new(Assistant::Service) do
        def execute = :ok
      end

      service = klass.new
      first  = service.run
      second = service.run

      assert_same first, second
    end

    def test_run_called_twice_does_not_duplicate_logs_on_success
      klass = Class.new(Assistant::Service) do
        def validate
          add_log(level: :warning, source: :validate, detail: :check, message: 'heads up')
        end

        def execute = :ok
      end

      service = klass.new
      service.run
      service.run

      assert_equal 1, service.warnings.size
    end

    def test_run_called_twice_does_not_duplicate_error_logs
      klass = Class.new(Assistant::Service) do
        def validate
          add_log(level: :error, source: :validate, detail: :check, message: 'boom')
        end

        def execute = :never
      end

      service = klass.new
      service.run
      service.run

      assert_equal 1, service.errors.size
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

    # ---- M-S2: call_service composition ----

    def build_doubler_service
      Class.new(Assistant::Service) do
        input :n, type: Integer, required: true
        def execute = n * 2
      end
    end

    def build_warner_service
      Class.new(Assistant::Service) do
        def validate
          add_log(level: :warning, source: :validate, detail: :slow, message: 'heads up')
        end

        def execute = :inner_ok
      end
    end

    def test_call_service_returns_inner_service_instance
      doubler = build_doubler_service
      outer_class = Class.new(Assistant::Service)
      outer_class.define_method(:execute) { call_service(doubler, n: 21) }

      outer = outer_class.new
      outer.run

      assert_kind_of doubler, outer.result
      assert_equal 42, outer.result.result
    end

    def test_call_service_passes_keyword_inputs_to_inner
      doubler = build_doubler_service
      outer_class = Class.new(Assistant::Service)
      outer_class.define_method(:execute) { call_service(doubler, n: 7).result }

      outcome = outer_class.run

      assert_equal 14, outcome[:result]
      assert_equal :ok, outcome[:status]
    end

    def test_call_service_merges_inner_logs_into_outer
      warner = build_warner_service
      outer_class = Class.new(Assistant::Service)
      outer_class.define_method(:execute) { call_service(warner) }

      outer = outer_class.new
      outer.run

      assert_equal 1, outer.logs.size
      assert_equal :warning, outer.logs.first.level
      assert_equal 'heads up', outer.logs.first.message
    end

    def test_call_service_inner_warning_propagates_to_with_warnings_status
      warner = build_warner_service
      outer_class = Class.new(Assistant::Service)
      outer_class.define_method(:execute) { call_service(warner) }

      outcome = outer_class.run

      assert_equal :with_warnings, outcome[:status]
      assert_equal 1, outcome[:warnings].size
    end

    def test_call_service_inner_error_propagates_to_with_errors_status
      doubler = build_doubler_service
      outer_class = Class.new(Assistant::Service)
      outer_class.define_method(:execute) { call_service(doubler) } # missing required :n

      outcome = outer_class.run

      assert_equal :with_errors, outcome[:status]
      assert_nil outcome[:result]
      refute_empty outcome[:errors]
    end

    def test_call_service_outer_failure_predicate_reflects_inner_error
      doubler = build_doubler_service
      outer_class = Class.new(Assistant::Service)
      outer_class.define_method(:execute) do
        call_service(doubler) # missing :n -> inner failure
        :outer_executed
      end

      outer = outer_class.new
      outer.run

      assert_predicate outer, :failure?
    end

    def test_call_service_allows_early_return_pattern_from_features_doc
      doubler = build_doubler_service
      outer_class = Class.new(Assistant::Service)
      outer_class.define_method(:execute) do
        inner = call_service(doubler) # missing :n -> failure
        return if failure?

        inner.result + 1
      end

      outcome = outer_class.run

      assert_equal :with_errors, outcome[:status]
      assert_nil outcome[:result]
    end

    def test_call_service_log_order_preserves_outer_then_inner_then_outer
      doubler = build_doubler_service
      outer_class = Class.new(Assistant::Service)
      outer_class.define_method(:execute) do
        add_log(level: :info, source: :execute, detail: :before, message: 'pre')
        call_service(doubler, n: 1)
        add_log(level: :info, source: :execute, detail: :after, message: 'post')
      end

      outer = outer_class.new
      outer.run

      # inner doubler logs nothing, so only the two outer infos are present
      assert_equal %i[before after], outer.logs.map(&:detail)
    end

    def test_call_service_multiple_inner_errors_all_propagate
      doubler = build_doubler_service
      outer_class = Class.new(Assistant::Service)
      outer_class.define_method(:execute) do
        call_service(doubler) # error 1
        call_service(doubler) # error 2
      end

      outcome = outer_class.run

      assert_equal :with_errors, outcome[:status]
      assert_equal 2, outcome[:errors].size
    end

    def test_call_service_with_non_class_raises_argument_error
      outer = Assistant::Service.new
      error = assert_raises(ArgumentError) { outer.send(:call_service, :not_a_class) }

      assert_match(/Assistant::Service subclass/, error.message)
    end

    def test_call_service_with_non_service_class_raises_argument_error
      outer = Assistant::Service.new
      error = assert_raises(ArgumentError) { outer.send(:call_service, String) }

      assert_match(/Assistant::Service subclass/, error.message)
    end

    def test_call_service_with_service_base_class_itself_is_allowed
      outer_class = Class.new(Assistant::Service)
      outer_class.define_method(:execute) { call_service(Assistant::Service) }

      outcome = outer_class.run

      assert_equal :ok, outcome[:status]
    end

    def test_call_service_does_not_swallow_inner_execute_exceptions
      raiser = Class.new(Assistant::Service) do
        def execute = raise 'inner boom'
      end

      outer_class = Class.new(Assistant::Service)
      outer_class.define_method(:execute) { call_service(raiser) }

      assert_raises(RuntimeError) { outer_class.run }
    end

    def test_call_service_inner_notifier_events_fire_independently
      events = with_recording_notifier
      doubler = build_doubler_service
      outer_class = Class.new(Assistant::Service)
      outer_class.define_method(:execute) { call_service(doubler, n: 1) }

      outer_class.run

      # outer: started, validated, executed; inner: started, validated, executed.
      # Notifier sees both lifecycles, ordered by emission.
      assert_equal 6, events.size
      assert_equal %i[service_started service_validated service_started service_validated
                      service_executed service_executed],
                   events.map(&:first)
    end

    # ---- M-S4: input_snapshot ----

    def test_input_snapshot_returns_data_instance_with_declared_members
      klass = Class.new(Assistant::Service) do
        input :name, type: String, required: true
        input :age,  type: Integer
      end

      snapshot = klass.new(name: 'Ada', age: 37).input_snapshot

      assert_kind_of Data, snapshot
      assert_equal 'Ada', snapshot.name
      assert_equal 37, snapshot.age
    end

    def test_input_snapshot_preserves_declaration_order
      klass = Class.new(Assistant::Service) do
        input :z, type: Integer
        input :a, type: Integer
        input :m, type: Integer
      end

      snapshot = klass.new(z: 1, a: 2, m: 3).input_snapshot

      assert_equal %i[z a m], snapshot.members
    end

    def test_input_snapshot_is_structurally_immutable
      klass = Class.new(Assistant::Service) do
        input :n, type: Integer
      end

      snapshot = klass.new(n: 1).input_snapshot

      assert_predicate snapshot, :frozen?
      assert_raises(NoMethodError) { snapshot.n = 2 }
    end

    def test_input_snapshot_reflects_m1_defaults
      klass = Class.new(Assistant::Service) do
        input :limit, type: Integer, default: 25
        input :now,   type: Time,    default: -> { Time.utc(2024, 1, 1) }
      end

      snapshot = klass.new.input_snapshot

      assert_equal 25, snapshot.limit
      assert_equal Time.utc(2024, 1, 1), snapshot.now
    end

    def test_input_snapshot_with_m2_allow_nil_keeps_explicit_nil
      klass = Class.new(Assistant::Service) do
        input :note, type: String, allow_nil: true
      end

      snapshot = klass.new(note: nil).input_snapshot

      assert_nil snapshot.note
    end

    def test_input_snapshot_with_m1_default_and_m2_allow_nil_explicit_nil_skips_default
      # M1's shipped semantics (see CHANGELOG M1 entry): with
      # `allow_nil: true`, an explicit `nil` from the caller is
      # honoured and the default is skipped. The snapshot reflects
      # that post-`apply_input_defaults` value.
      klass = Class.new(Assistant::Service) do
        input :note, type: String, default: 'hi', allow_nil: true
      end

      assert_nil klass.new(note: nil).input_snapshot.note
      assert_equal 'hi', klass.new.input_snapshot.note
    end

    def test_input_snapshot_excludes_undeclared_kwargs
      klass = Class.new(Assistant::Service) do
        input :declared, type: String
      end

      snapshot = klass.new(declared: 'yes', undeclared: 'no').input_snapshot

      assert_equal %i[declared], snapshot.members
      refute_respond_to snapshot, :undeclared
    end

    def test_input_snapshot_for_service_with_no_inputs_is_empty_data
      snapshot = Assistant::Service.new.input_snapshot

      assert_kind_of Data, snapshot
      assert_empty snapshot.members
    end

    def test_input_snapshot_missing_required_input_appears_as_nil
      # Snapshot can be called from validate or anywhere; it does not
      # require successful #run. A missing required input simply
      # surfaces as nil, matching the per-input getter behaviour.
      klass = Class.new(Assistant::Service) do
        input :name, type: String, required: true
      end

      snapshot = klass.new.input_snapshot

      assert_nil snapshot.name
    end

    def test_input_snapshot_class_is_memoised_per_subclass
      klass = Class.new(Assistant::Service) do
        input :n, type: Integer
      end

      assert_same klass.input_snapshot_class, klass.input_snapshot_class
    end

    def test_input_snapshot_class_differs_between_subclasses
      one = Class.new(Assistant::Service) { input :a, type: Integer }
      two = Class.new(Assistant::Service) { input :b, type: Integer }

      refute_same one.input_snapshot_class, two.input_snapshot_class
    end

    def test_input_snapshot_class_rebuilds_when_definitions_change
      klass = Class.new(Assistant::Service)
      klass.input :a, type: Integer
      first = klass.input_snapshot_class

      klass.input :b, type: Integer
      second = klass.input_snapshot_class

      refute_same first, second
      assert_equal %i[a b], second.members
    end

    def test_input_snapshot_returns_fresh_instance_each_call
      klass = Class.new(Assistant::Service) do
        input :n, type: Integer
      end
      svc = klass.new(n: 1)

      first = svc.input_snapshot
      second = svc.input_snapshot

      refute_same first, second
      assert_equal first, second
    end

    def test_input_snapshot_values_share_object_identity_with_inputs
      # Data is structurally immutable but does not deep-freeze members;
      # a mutable input value is the same object in the snapshot.
      mutable = [1, 2, 3]
      klass = Class.new(Assistant::Service) do
        input :xs, type: Array
      end

      snapshot = klass.new(xs: mutable).input_snapshot

      assert_same mutable, snapshot.xs
    end

    def test_input_snapshot_callable_from_inside_execute
      klass = Class.new(Assistant::Service) do
        input :n, type: Integer, required: true
        def execute = input_snapshot.n * 10
      end

      outcome = klass.run(n: 4)

      assert_equal 40, outcome[:result]
    end
  end
end

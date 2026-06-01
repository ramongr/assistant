# frozen_string_literal: true

module Assistant
  class ServiceTest < Minitest::Test
    # frozen_string_literal: true

    require_relative '../test_helper'
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
  end
end

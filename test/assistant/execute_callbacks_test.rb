# frozen_string_literal: true

require_relative '../test_helper'

module Assistant
  class ExecuteCallbacksTest < Minitest::Test
    # ---- DSL surface ----

    def test_service_class_responds_to_execute_callback_dsl
      assert_respond_to Assistant::Service, :before_execute
      assert_respond_to Assistant::Service, :after_execute
      assert_respond_to Assistant::Service, :around_execute
    end

    def test_before_execute_requires_a_block
      klass = Class.new(Assistant::Service)
      assert_raises(ArgumentError) { klass.before_execute }
    end

    def test_after_execute_requires_a_block
      klass = Class.new(Assistant::Service)
      assert_raises(ArgumentError) { klass.after_execute }
    end

    def test_around_execute_requires_a_block
      klass = Class.new(Assistant::Service)
      assert_raises(ArgumentError) { klass.around_execute }
    end

    def test_base_service_class_has_no_registered_hooks
      assert_empty Assistant::Service.before_execute_hooks
      assert_empty Assistant::Service.after_execute_hooks
      assert_empty Assistant::Service.around_execute_hooks
    end

    def test_fresh_subclass_starts_with_empty_hook_arrays
      klass = Class.new(Assistant::Service)

      assert_empty klass.before_execute_hooks
      assert_empty klass.after_execute_hooks
      assert_empty klass.around_execute_hooks
    end

    # ---- before_execute ----

    def test_before_execute_runs_before_execute_with_service_as_self
      seen = []
      klass = Class.new(Assistant::Service) do
        before_execute { seen << [:before, self] }
        define_method(:execute) do
          seen << [:execute, self]
          :ok
        end
      end

      instance = klass.new
      instance.run

      assert_equal :before,  seen[0][0]
      assert_equal :execute, seen[1][0]
      assert_same instance, seen[0][1]
      assert_same instance, seen[1][1]
    end

    def test_before_execute_runs_after_validation
      seen = []
      klass = Class.new(Assistant::Service) do
        define_method(:validate) { seen << :validate }
        before_execute { seen << :before }
        define_method(:execute) { seen << :execute }
      end

      klass.run

      assert_equal %i[validate before execute], seen
    end

    def test_multiple_before_execute_hooks_run_in_declaration_order
      seen = []
      klass = Class.new(Assistant::Service) do
        before_execute { seen << :first }
        before_execute { seen << :second }
        before_execute { seen << :third }
        def execute = :ok
      end

      klass.run

      assert_equal %i[first second third], seen
    end

    def test_before_execute_can_add_logs
      klass = Class.new(Assistant::Service) do
        before_execute do
          add_log(level: :info, source: :hook, detail: :marker, message: 'from before')
        end
        def execute = :ok
      end

      instance = klass.new
      instance.run

      assert(instance.infos.any? { |l| l.message == 'from before' })
    end

    # ---- after_execute ----

    def test_after_execute_runs_after_execute_with_result_and_service_self
      seen = []
      klass = Class.new(Assistant::Service) do
        after_execute { |result| seen << [:after, result, self] }
        def execute = :the_result
      end

      instance = klass.new
      instance.run

      assert_equal [:after, :the_result, instance], seen.first
    end

    def test_multiple_after_execute_hooks_run_in_declaration_order
      seen = []
      klass = Class.new(Assistant::Service) do
        after_execute { |_r| seen << :first }
        after_execute { |_r| seen << :second }
        after_execute { |_r| seen << :third }
        def execute = :ok
      end

      klass.run

      assert_equal %i[first second third], seen
    end

    # ---- around_execute ----

    def test_around_execute_can_wrap_execute_and_return_modified_value
      klass = Class.new(Assistant::Service) do
        around_execute do |&blk|
          inner = blk.call
          inner.to_s.upcase
        end
        def execute = 'hello'
      end

      outcome = klass.run

      assert_equal 'HELLO', outcome[:result]
    end

    def test_around_execute_has_service_as_self_and_yields_to_execute
      seen = []
      klass = Class.new(Assistant::Service) do
        around_execute do |&blk|
          seen << [:around_in, self]
          inner = blk.call
          seen << [:around_out, self, inner]
          inner
        end
        define_method(:execute) do
          seen << [:execute, self]
          :ok
        end
      end

      instance = klass.new
      instance.run

      assert_equal :around_in,  seen[0][0]
      assert_equal :execute,    seen[1][0]
      assert_equal :around_out, seen[2][0]
      assert_same instance, seen[0][1]
      assert_same instance, seen[1][1]
      assert_same instance, seen[2][1]
      assert_equal :ok, seen[2][2]
    end

    def test_around_execute_declaration_order_wraps_first_is_outermost
      seen = []
      klass = Class.new(Assistant::Service) do
        around_execute do |&blk|
          seen << :a_in
          blk.call
          seen << :a_out
        end
        around_execute do |&blk|
          seen << :b_in
          blk.call
          seen << :b_out
        end
        define_method(:execute) { seen << :execute }
      end

      klass.run

      assert_equal %i[a_in b_in execute b_out a_out], seen
    end

    def test_around_execute_chain_composes_with_before_and_after
      seen = []
      klass = Class.new(Assistant::Service) do
        before_execute { seen << :before }
        around_execute do |&blk|
          seen << :around_in
          blk.call
          seen << :around_out
        end
        after_execute { |_r| seen << :after }
        define_method(:execute) { seen << :execute }
      end

      klass.run

      assert_equal %i[before around_in execute around_out after], seen
    end

    # ---- Error semantics (M-S1 spec) ----

    def test_before_execute_exception_is_logged_and_does_not_propagate
      klass = Class.new(Assistant::Service) do
        before_execute { raise 'before boom' }
        def execute = :ok
      end

      instance = klass.new
      outcome = instance.run

      hook_errors = instance.errors.select { |l| l.source == :hook }

      assert_equal 1, hook_errors.size
      assert_equal :before_execute, hook_errors.first.detail
      assert_match(/before boom/, hook_errors.first.message)
      assert_equal :with_errors, outcome[:status]
    end

    def test_after_execute_exception_is_logged_and_does_not_propagate
      klass = Class.new(Assistant::Service) do
        after_execute { |_r| raise 'after boom' }
        def execute = :ok
      end

      instance = klass.new
      outcome = instance.run

      hook_errors = instance.errors.select { |l| l.source == :hook }

      assert_equal 1, hook_errors.size
      assert_equal :after_execute, hook_errors.first.detail
      assert_match(/after boom/, hook_errors.first.message)
      assert_equal :with_errors, outcome[:status]
    end

    def test_around_execute_exception_is_logged_and_does_not_propagate
      klass = Class.new(Assistant::Service) do
        around_execute { |&_blk| raise 'around boom' }
        def execute = :ok
      end

      instance = klass.new
      outcome = instance.run

      hook_errors = instance.errors.select { |l| l.source == :hook }

      assert_equal 1, hook_errors.size
      assert_equal :around_execute, hook_errors.first.detail
      assert_match(/around boom/, hook_errors.first.message)
      assert_equal :with_errors, outcome[:status]
    end

    def test_hook_error_log_uses_source_hook
      klass = Class.new(Assistant::Service) do
        before_execute { raise 'boom' }
        def execute = :ok
      end

      instance = klass.new
      instance.run

      assert(instance.errors.any? { |l| l.source == :hook })
    end

    def test_hook_error_log_includes_exception_class_in_message
      klass = Class.new(Assistant::Service) do
        before_execute { raise ArgumentError, 'bad arg' }
        def execute = :ok
      end

      instance = klass.new
      instance.run

      hook_log = instance.errors.find { |l| l.source == :hook }

      assert_includes hook_log.message, 'ArgumentError'
      assert_includes hook_log.message, 'bad arg'
    end

    def test_hook_error_log_preserves_backtrace_on_trace
      klass = Class.new(Assistant::Service) do
        before_execute { raise 'boom' }
        def execute = :ok
      end

      instance = klass.new
      instance.run

      hook_log = instance.errors.find { |l| l.source == :hook }

      assert_kind_of Array, hook_log.trace
      refute_empty hook_log.trace
    end

    def test_one_before_hook_raising_does_not_skip_subsequent_before_hooks
      seen = []
      klass = Class.new(Assistant::Service) do
        before_execute do
          seen << :one
          raise 'one boom'
        end
        before_execute { seen << :two }
        before_execute { seen << :three }
        def execute = :ok
      end

      klass.run

      assert_equal %i[one two three], seen
    end

    def test_one_after_hook_raising_does_not_skip_subsequent_after_hooks
      seen = []
      klass = Class.new(Assistant::Service) do
        after_execute do |_r|
          seen << :one
          raise 'one boom'
        end
        after_execute { |_r| seen << :two }
        after_execute { |_r| seen << :three }
        def execute = :ok
      end

      klass.run

      assert_equal %i[one two three], seen
    end

    def test_around_hook_that_raises_before_continuation_skips_execute_for_that_layer
      seen = []
      klass = Class.new(Assistant::Service) do
        around_execute do |&_blk|
          seen << :raising
          raise 'before continuation'
        end
        define_method(:execute) { seen << :execute }
      end

      klass.run

      assert_equal [:raising], seen
    end

    def test_outer_around_hooks_still_wrap_when_inner_around_raises
      seen = []
      klass = Class.new(Assistant::Service) do
        around_execute do |&blk|
          seen << :outer_in
          blk.call
          seen << :outer_out
        end
        around_execute do |&_blk|
          seen << :inner_raising
          raise 'inner boom'
        end
        define_method(:execute) { seen << :execute }
      end

      klass.run

      assert_equal %i[outer_in inner_raising outer_out], seen
    end

    def test_execute_exception_propagates_through_hook_chain
      klass = Class.new(Assistant::Service) do
        def execute = raise('execute boom')
      end

      assert_raises(RuntimeError) { klass.run }
    end

    # ---- Inheritance ----

    def test_subclass_inherits_parent_before_hooks
      seen = []
      parent = Class.new(Assistant::Service) do
        before_execute { seen << :parent_before }
        def execute = :ok
      end
      child = Class.new(parent)

      child.run

      assert_equal [:parent_before], seen
    end

    def test_subclass_inherits_parent_around_and_after_hooks_in_order
      seen = []
      parent = Class.new(Assistant::Service) do
        around_execute do |&blk|
          seen << :parent_around_in
          blk.call
          seen << :parent_around_out
        end
        after_execute { |_r| seen << :parent_after }
        define_method(:execute) { seen << :execute }
      end
      child = Class.new(parent)

      child.run

      assert_equal %i[parent_around_in execute parent_around_out parent_after], seen
    end

    def test_subclass_can_add_hooks_in_addition_to_inherited_ones
      seen = []
      parent = Class.new(Assistant::Service) do
        before_execute { seen << :parent_before }
        def execute = :ok
      end
      child = Class.new(parent) do
        before_execute { seen << :child_before }
      end

      child.run

      assert_equal %i[parent_before child_before], seen
    end

    def test_adding_hook_to_subclass_does_not_affect_parent
      seen = []
      parent = Class.new(Assistant::Service) do
        def execute = :ok
      end
      Class.new(parent) do
        before_execute { seen << :child_only }
      end

      parent.run

      assert_empty seen
    end

    def test_adding_hook_to_parent_after_subclass_definition_does_not_affect_subclass
      parent = Class.new(Assistant::Service) do
        def execute = :ok
      end
      child = Class.new(parent)
      parent.before_execute { raise 'should not run on child' }

      instance = child.new
      outcome = instance.run

      # Child snapshotted parent's (empty) hook list at definition time,
      # so the parent's later-added before_execute is invisible to it.
      assert_empty instance.errors
      assert_equal :ok, outcome[:status]
    end

    # ---- result memoization + no-hooks path ----

    def test_calling_result_directly_runs_hooks_once
      call_count = 0
      klass = Class.new(Assistant::Service) do
        before_execute { call_count += 1 }
        def execute = :ok
      end

      instance = klass.new
      instance.result
      instance.result
      instance.result

      assert_equal 1, call_count
    end

    def test_service_without_hooks_executes_normally
      klass = Class.new(Assistant::Service) do
        def execute = 42
      end

      outcome = klass.run

      assert_equal 42, outcome[:result]
      assert_equal :ok, outcome[:status]
    end
  end
end

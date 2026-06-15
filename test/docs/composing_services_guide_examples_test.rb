# frozen_string_literal: true

require_relative '../test_helper'

# Integration tests mirroring the runnable examples in
# docs/guides/composing-services.md.
class ComposingServicesGuideExamplesTest < Minitest::Test
  include TestHelpers::IoCapture

  class CreateUser < Assistant::Service
    input :email, type: String, required: true
    def execute = { id: 1, email: }
  end

  class SignUp < Assistant::Service
    input :email, type: String, required: true

    def execute
      user = call_service(CreateUser, email:)
      return if user.failure?

      { user: user.result, signed_up_at: Time.now }
    end
  end

  def test_call_service_success_path
    payload = SignUp.run(email: 'a@b.com')

    assert_equal :ok, payload.fetch(:status)
    assert_equal 1, payload.fetch(:result).fetch(:user).fetch(:id)
  end

  def test_call_service_propagates_inner_failure_to_outer_status
    payload = SignUp.run(email: '')

    assert_equal :with_errors, payload.fetch(:status)
    assert_nil payload.fetch(:result)
  end

  def test_call_service_rejects_non_service_class
    err = assert_raises(ArgumentError) do
      Class.new(Assistant::Service) do
        define_method(:execute) { call_service(String, foo: 1) }
      end.run
    end
    assert_match(/expects an Assistant::Service subclass/, err.message)
  end

  class HookedService < Assistant::Service
    input :email, type: String, required: true

    before_execute do
      log_item_info(source: :hook, detail: :before, message: "starting #{email}")
    end

    around_execute do |&blk|
      log_item_info(source: :hook, detail: :around_in, message: 'around in')
      value = blk.call
      log_item_info(source: :hook, detail: :around_out, message: 'around out')
      value
    end

    after_execute do |result|
      log_item_info(source: :hook, detail: :after, message: "result=#{result.inspect}")
    end

    def execute = { id: 1, email: }
  end

  def test_hooks_run_in_documented_order
    svc = HookedService.new(email: 'a@b.com')
    svc.run

    sequence = svc.infos.map(&:detail)

    assert_equal %i[before around_in around_out after], sequence
  end

  def test_hook_block_required
    assert_raises(ArgumentError) do
      Class.new(Assistant::Service) { before_execute }
    end
  end

  class ChildHooked < HookedService
    before_execute do
      log_item_info(source: :hook, detail: :before_child, message: 'child')
    end
  end

  def test_hook_inheritance_is_a_dup
    parent_count = HookedService.before_execute_hooks.size # force registration via the before_execute block above

    assert_equal parent_count, HookedService.before_execute_hooks.size
    assert_equal parent_count + 1, ChildHooked.before_execute_hooks.size
  end

  class NotifierService < Assistant::Service
    input :name, type: String, required: true
    def execute = name.upcase
  end

  def test_notifier_receives_lifecycle_events_with_payload
    events = []
    Assistant.notifier = ->(event, payload) { events << [event, payload[:service_class]] }

    NotifierService.run(name: 'ada')

    event_names = events.map(&:first)

    assert_includes event_names, :service_started
    assert_includes event_names, :service_validated
    assert_includes event_names, :service_executed
    assert(events.all? { |_, klass| klass == NotifierService })
  ensure
    Assistant.notifier = nil
  end

  def test_notifier_failure_emits_service_failed
    events = []
    Assistant.notifier = ->(event, _payload) { events << event }

    NotifierService.run # missing required :name -> :with_errors

    assert_includes events, :service_failed
  ensure
    Assistant.notifier = nil
  end

  def test_notifier_exception_is_swallowed_with_warning
    Assistant.notifier = ->(_event, _payload) { raise 'boom' }

    err = capture_io_warn { NotifierService.run(name: 'ada') }

    assert_match(/notifier raised/, err)
  ensure
    Assistant.notifier = nil
  end

  class Snapshotter < Assistant::Service
    input :email, type: String, required: true
    input :role,  type: Symbol, default: :member

    def execute = input_snapshot.to_h
  end

  def test_input_snapshot_is_immutable_data_view
    instance = Snapshotter.new(email: 'a@b.com')
    instance.run
    snap = instance.input_snapshot

    assert_kind_of Data, snap
    assert_equal 'a@b.com', snap.email
    assert_equal :member,   snap.role
    assert_equal({ email: 'a@b.com', role: :member }, snap.to_h)
  end
end

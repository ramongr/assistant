# frozen_string_literal: true

require_relative '../test_helper'

# Integration tests mirroring the runnable examples in docs/guides/inputs.md.
class InputsGuideExamplesTest < Minitest::Test
  class TypeChecked < Assistant::Service
    input :email, type: String

    def execute = email
  end

  def test_type_mismatch_message_matches_doc_literal
    payload = TypeChecked.run(email: 42)

    assert_equal :with_errors, payload.fetch(:status)
    err = payload.fetch(:errors).first

    assert_equal :email, err.detail
    assert_equal 'Service argument with name email is not a String but Integer', err.message
  end

  class MultiType < Assistant::Service
    input :id, type: [String, Integer]

    def execute = id
  end

  def test_multi_type_accepts_either
    assert_equal :ok, MultiType.run(id: 'abc').fetch(:status)
    assert_equal :ok, MultiType.run(id: 7).fetch(:status)
  end

  def test_multi_type_rejects_outsider
    payload = MultiType.run(id: :sym)

    assert_equal :with_errors, payload.fetch(:status)
    assert_match(/not one of \[String, Integer\] but Symbol/, payload.fetch(:errors).first.message)
  end

  class RequiredOnly < Assistant::Service
    input :email, type: String, required: true

    def execute = email
  end

  def test_required_missing_message_matches_doc_literal
    payload = RequiredOnly.run(email: '')

    assert_equal :with_errors, payload.fetch(:status)
    err = payload.fetch(:errors).first

    assert_equal :email, err.detail
    assert_equal 'Service is missing argument with name email', err.message
  end

  class WithDefault < Assistant::Service
    input :role, type: Symbol, default: :member

    def execute = role
  end

  def test_default_fires_when_key_absent
    assert_equal :member, WithDefault.run.fetch(:result)
    assert_equal :admin,  WithDefault.run(role: :admin).fetch(:result)
  end

  def test_proc_default_must_be_zero_arity
    err = assert_raises(ArgumentError) do
      Class.new(Assistant::Service) do
        input :uuid, type: String, default: ->(svc) { svc.object_id.to_s }
      end
    end
    assert_match(/arity/i, err.message)
  end

  class AllowNilTypeCheck < Assistant::Service
    input :age, type: Integer, allow_nil: true

    def execute = age
  end

  def test_allow_nil_passes_type_check_with_explicit_nil
    payload = AllowNilTypeCheck.run(age: nil)

    assert_equal :ok, payload.fetch(:status)
    assert_nil payload.fetch(:result)
  end

  class OptionalNickname < Assistant::Service
    input :nickname, type: String, optional: true

    def execute = nickname.to_s.upcase
  end

  def test_optional_input_does_not_error_when_missing
    payload = OptionalNickname.run

    assert_equal :ok, payload.fetch(:status)
    assert_equal '', payload.fetch(:result)
  end

  def test_optional_collides_with_required_at_class_definition
    err = assert_raises(ArgumentError) do
      Class.new(Assistant::Service) do
        input :nope, type: String, required: true, optional: true
      end
    end
    assert_match(/cannot be both required: true and optional: true/, err.message)
  end

  class ConditionalRequire < Assistant::Service
    input :role,   type: Symbol, default: :member
    input :reason, type: String, required: true, if: ->(_value) { true }

    def execute = { role:, reason: }
  end

  def test_conditional_required_predicate_receives_input_value
    assert_equal :with_errors, ConditionalRequire.run(role: :member).fetch(:status)
    assert_equal :ok, ConditionalRequire.run(role: :member, reason: 'audit').fetch(:status)
  end

  class Bulk < Assistant::Service
    inputs %i[first last], type: String, required: true

    def execute = "#{first} #{last}"
  end

  def test_inputs_bulk_declares_all_attrs
    assert_equal 'Ada Lovelace', Bulk.run(first: 'Ada', last: 'Lovelace').fetch(:result)
  end

  class Snapshotter < Assistant::Service
    input :email, type: String, required: true
    input :role,  type: Symbol, default: :member

    def execute = input_snapshot.to_h
  end

  def test_input_snapshot_is_a_data_view_of_declared_inputs
    instance = Snapshotter.new(email: 'a@b.com')
    instance.run
    snap = instance.input_snapshot

    assert_kind_of Data, snap
    assert_equal 'a@b.com', snap.email
    assert_equal :member,   snap.role
    assert_equal({ email: 'a@b.com', role: :member }, snap.to_h)
  end
end

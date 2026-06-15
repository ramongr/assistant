# frozen_string_literal: true

require_relative '../test_helper'

# Integration tests mirroring the runnable examples in docs/guides/validation.md.
class ValidationGuideExamplesTest < Minitest::Test
  class CreateUserSimple < Assistant::Service
    input :email, type: String, required: true

    def validate
      return if email.include?('@')

      log_item_error(source: :validate, detail: :email, message: 'must contain @')
    end

    def execute = { email: }
  end

  def test_happy_path
    assert_equal :ok, CreateUserSimple.run(email: 'a@b.com').fetch(:status)
  end

  def test_validate_logs_error_short_circuits_execute
    payload = CreateUserSimple.run(email: 'oops')

    assert_equal :with_errors, payload.fetch(:status)
    assert_nil payload.fetch(:result)
  end

  class WarningVsError < Assistant::Service
    input :email, type: String,  required: true
    input :age,   type: Integer, allow_nil: true, default: nil

    def validate
      log_item_error(source: :validate, detail: :email, message: 'invalid email') unless email.include?('@')
      log_item_warning(source: :validate, detail: :age, message: 'age missing') if age.nil?
    end

    def execute = { email:, age: }
  end

  def test_warning_does_not_skip_execute
    payload = WarningVsError.run(email: 'a@b.com')

    assert_equal :with_warnings, payload.fetch(:status)
    assert_equal({ email: 'a@b.com', age: nil }, payload.fetch(:result))
  end

  def test_error_skips_execute
    payload = WarningVsError.run(email: 'oops')

    assert_equal :with_errors, payload.fetch(:status)
    assert_nil payload.fetch(:result)
  end

  class UpdateUser < Assistant::Service
    input :role,   type: Symbol, default: :member
    input :reason, type: String, required: true, if: ->(_value) { true }

    def execute = { role:, reason: }
  end

  def test_conditional_required_failure_and_success
    assert_equal :with_errors, UpdateUser.run(role: :member).fetch(:status)
    assert_equal :ok, UpdateUser.run(role: :member, reason: 'audit cleanup').fetch(:status)
  end

  def test_log_item_constructor_is_strict_in_one_zero
    item = Assistant::LogItem.new(level: :info, source: :a, detail: :b, message: 'ok')

    assert_predicate item, :valid?

    err = assert_raises(ArgumentError) do
      Assistant::LogItem.new(level: :info, source: :a, detail: :b, message: '')
    end
    assert_equal 'invalid LogItem: message must be present', err.message
  end
end

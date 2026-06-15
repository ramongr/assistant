# frozen_string_literal: true

require_relative '../test_helper'

# Integration tests mirroring the runnable examples in
# docs/getting-started.md. The intent is to keep the docs honest:
# if a literal output in the markdown drifts from runtime behavior,
# the matching assertion here breaks.
class GettingStartedExamplesTest < Minitest::Test
  class CreateUser < Assistant::Service
    input :email, type: String,  required: true
    input :age,   type: Integer, allow_nil: true, default: nil

    def validate
      return if email.include?('@')

      log_item_error(source: :validate, detail: :email, message: 'must contain @')
    end

    def execute
      log_item_warning(source: :execute, detail: :age, message: 'age missing') if age.nil?

      { id: 42, email:, age: }
    end
  end

  def test_happy_path_returns_ok_status
    payload = CreateUser.run(email: 'a@b.com', age: 30)

    assert_equal :ok, payload.fetch(:status)
    assert_equal({ id: 42, email: 'a@b.com', age: 30 }, payload.fetch(:result))
    assert_empty payload.fetch(:warnings)
  end

  def test_missing_age_demotes_to_with_warnings
    payload = CreateUser.run(email: 'a@b.com')

    assert_equal :with_warnings, payload.fetch(:status)
    assert_equal({ id: 42, email: 'a@b.com', age: nil }, payload.fetch(:result))
    assert_equal 1, payload.fetch(:warnings).size
  end

  def test_invalid_email_yields_with_errors
    payload = CreateUser.run(email: 'oops')

    assert_equal :with_errors, payload.fetch(:status)
    assert_nil payload.fetch(:result)
    refute_empty payload.fetch(:errors)
  end

  def test_pattern_match_consumption_shape
    payload = CreateUser.run(email: 'a@b.com', age: 30)

    extracted =
      case payload
      in { result:, status: :ok | :with_warnings }
        result
      in { errors:, status: :with_errors }
        errors
      end

    assert_equal({ id: 42, email: 'a@b.com', age: 30 }, extracted)
  end
end

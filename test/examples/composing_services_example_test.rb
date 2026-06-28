# frozen_string_literal: true

require_relative 'test_helper'

require File.join(ExampleTestHelpers::EXAMPLES_ROOT, 'composing_services/sign_up_user')

# Regression test for `examples/composing_services/` (P9 of
# docs/v1/index.md). Pins the merged-timeline shape
# documented in `docs/examples/composing-services.md` lines 27-36:
# `#call_service` merges each inner service's `#logs` into the outer
# `@logs` in declaration order, so `CreateUser`'s `:email_normalized`
# warning lands before `SendWelcomeEmail`'s `:throttled` warning, and
# the outer status downgrades to `:with_warnings`.
class ComposingServicesExampleTest < Minitest::Test
  def test_happy_path_returns_inner_user_with_normalized_email
    payload = ComposingServicesExample::SignUpUser.run(email: 'A@B.com', name: 'Alice')

    assert_equal :with_warnings, payload.fetch(:status)

    user = payload.fetch(:result)

    assert_equal 42, user.id
    assert_equal 'a@b.com', user.email
    assert_equal 'Alice', user.name
  end

  def test_happy_path_merges_inner_warnings_in_declaration_order
    payload = ComposingServicesExample::SignUpUser.run(email: 'A@B.com', name: 'Alice')
    warnings = payload.fetch(:warnings)

    assert_equal 2, warnings.size

    first, second = warnings

    assert_equal %i[create_user email_normalized], [first.source, first.detail]
    assert_equal 'normalized to a@b.com', first.message

    assert_equal %i[send_welcome_email throttled], [second.source, second.detail]
    assert_equal 'welcome queued for 1s delay', second.message
  end

  def test_inner_failure_short_circuits_before_send_welcome_email_runs
    payload = ComposingServicesExample::SignUpUser.run(email: 'oops', name: 'Alice')

    assert_equal :with_errors, payload.fetch(:status)
    assert_nil payload.fetch(:result)

    errors = payload.fetch(:errors)

    assert_equal 1, errors.size

    error = errors.first

    assert_equal :validate, error.source
    assert_equal :email, error.detail
    assert_equal 'must contain @', error.message
  end

  def test_inner_failure_does_not_log_send_welcome_email_throttled_warning
    service = ComposingServicesExample::SignUpUser.new(email: 'oops', name: 'Alice')
    service.run

    refute(service.logs.any? { |log| log.detail == :throttled },
           'SendWelcomeEmail should not have run when CreateUser failed')
  end
end

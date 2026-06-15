# frozen_string_literal: true

require_relative 'test_helper'

require File.join(ExampleTestHelpers::EXAMPLES_ROOT, 'rails_service/users_controller')

# Regression test for `examples/rails_service/` (P6 of
# docs/v1/08-github-pages.md). Exercises every `case … in …` branch of
# `Examples::RailsService::UsersController#create` so the response
# shape promised by `docs/examples/rails-service.md` stays honest.
class RailsServiceExampleTest < Minitest::Test
  # Recording double that captures every `warn` argument so the test
  # can assert on the `LogItem#item` fan-out without a real logger.
  class RecordingLogger
    attr_reader :warnings

    def initialize
      @warnings = []
    end

    def warn(items)
      @warnings.concat(items)
    end
  end

  def setup
    @logger = RecordingLogger.new
  end

  def test_happy_path_returns_created_with_user_body
    controller = build_controller(user: { email: 'a@b.com', name: 'Alice', age: 30 })

    response = controller.create

    assert_equal :created, response.fetch(:status)
    assert_equal({ id: 42, email: 'a@b.com', name: 'Alice', age: 30 }, response.fetch(:body))
    assert_empty @logger.warnings
  end

  def test_missing_age_returns_created_and_logs_warning
    controller = build_controller(user: { email: 'a@b.com', name: 'Alice' })

    response = controller.create

    assert_equal :created, response.fetch(:status)
    assert_equal({ id: 42, email: 'a@b.com', name: 'Alice', age: nil }, response.fetch(:body))
    assert_equal 1, @logger.warnings.size

    warning = @logger.warnings.first

    assert_equal :execute, warning.fetch(:source)
    assert_equal :age, warning.fetch(:detail)
    assert_equal 'age missing', warning.fetch(:message)
  end

  def test_invalid_email_returns_unprocessable_entity_with_errors
    controller = build_controller(user: { email: 'oops', name: 'Bob' })

    response = controller.create

    assert_equal :unprocessable_entity, response.fetch(:status)
    errors = response.fetch(:body).fetch(:errors)

    assert_equal 1, errors.size
    assert_equal :validate, errors.first.fetch(:source)
    assert_equal :email, errors.first.fetch(:detail)
  end

  private

  def build_controller(user:)
    RailsServiceExample::UsersController.new(params: { user: }, logger: @logger)
  end
end

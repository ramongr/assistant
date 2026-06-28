# frozen_string_literal: true

require_relative 'test_helper'

require File.join(ExampleTestHelpers::EXAMPLES_ROOT, 'sidekiq_worker/create_user_worker')

# Regression test for `examples/sidekiq_worker/` (P8 of
# docs/v1/index.md). Exercises each `case … in …` branch of
# `CreateUserWorker#perform` and asserts on the right sink for each
# `:status`.
class SidekiqWorkerExampleTest < Minitest::Test
  def setup
    SidekiqWorkerExample::WarningsSink.clear
    SidekiqWorkerExample::ErrorsSink.clear
  end

  def test_happy_path_publishes_to_no_sink
    CreateUserWorker.new.perform('email' => 'a@b.com', 'name' => 'Alice')

    assert_empty SidekiqWorkerExample::WarningsSink.published
    assert_empty SidekiqWorkerExample::ErrorsSink.published
  end

  def test_with_warnings_publishes_to_warnings_sink_with_log_items
    CreateUserWorker.new.perform('email' => 'a@b.com', 'name' => 'alice')

    assert_empty SidekiqWorkerExample::ErrorsSink.published
    published = SidekiqWorkerExample::WarningsSink.published

    assert_equal 1, published.size

    entry = published.first

    assert_equal 'CreateUserWorker', entry.fetch(:worker)
    item = entry.fetch(:items).first

    assert_equal :execute, item.fetch(:source)
    assert_equal :name, item.fetch(:detail)
    assert_equal 'name not capitalized', item.fetch(:message)
  end

  def test_with_errors_publishes_to_errors_sink_with_log_items
    CreateUserWorker.new.perform('email' => 'oops', 'name' => 'Bob')

    assert_empty SidekiqWorkerExample::WarningsSink.published
    published = SidekiqWorkerExample::ErrorsSink.published

    assert_equal 1, published.size

    entry = published.first

    assert_equal 'CreateUserWorker', entry.fetch(:worker)
    item = entry.fetch(:items).first

    assert_equal :validate, item.fetch(:source)
    assert_equal :email, item.fetch(:detail)
    assert_equal 'must contain @', item.fetch(:message)
  end

  def test_sidekiq_options_are_recorded_on_the_worker_class
    options = CreateUserWorker.sidekiq_options_hash

    assert_equal 5, options.fetch(:retry)
    assert_equal :default, options.fetch(:queue)
  end
end

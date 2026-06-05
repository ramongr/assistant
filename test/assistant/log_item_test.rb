# frozen_string_literal: true

require_relative '../test_helper'

module Assistant
  class LogItemTest < Minitest::Test
    include TestHelpers::LogItems

    def test_log_item_with_invalid_level_raises
      error = assert_raises(ArgumentError) do
        Assistant::LogItem.new(level: '', source: :source, detail: :detail, message: 'message')
      end

      assert_match(/invalid LogItem/, error.message)
      assert_match(/level/, error.message)
    end

    def test_log_item_with_invalid_source_raises
      error = assert_raises(ArgumentError) do
        Assistant::LogItem.new(level: :info, source: '', detail: :detail, message: 'message')
      end

      assert_match(/source/, error.message)
    end

    def test_log_item_with_invalid_detail_raises
      error = assert_raises(ArgumentError) do
        Assistant::LogItem.new(level: :info, source: :source, detail: '', message: 'message')
      end

      assert_match(/detail/, error.message)
    end

    def test_log_item_with_invalid_message_raises
      error = assert_raises(ArgumentError) do
        Assistant::LogItem.new(level: :info, source: :source, detail: :detail, message: '')
      end

      assert_match(/message/, error.message)
    end

    def test_log_item_with_whitespace_message_raises
      error = assert_raises(ArgumentError) do
        Assistant::LogItem.new(level: :info, source: :source, detail: :detail, message: '   ')
      end

      assert_match(/message/, error.message)
    end

    def test_log_item_with_same_source_and_detail_raises_with_both_names
      error = assert_raises(ArgumentError) do
        Assistant::LogItem.new(level: :info, source: :same, detail: :same, message: 'message')
      end

      assert_match(/source/, error.message)
      assert_match(/detail/, error.message)
    end

    def test_log_item_with_multiple_invalid_attributes_aggregates_errors
      error = assert_raises(ArgumentError) do
        Assistant::LogItem.new(level: :invalid, source: '', detail: '', message: '')
      end

      assert_match(/level/, error.message)
      assert_match(/source/, error.message)
      assert_match(/detail/, error.message)
      assert_match(/message/, error.message)
    end

    def test_log_item_with_nil_attributes_raises_argument_error
      error = assert_raises(ArgumentError) do
        Assistant::LogItem.new(level: nil, source: nil, detail: nil, message: nil)
      end

      assert_match(/level/, error.message)
      assert_match(/source/, error.message)
      assert_match(/detail/, error.message)
      assert_match(/message/, error.message)
    end

    def test_info_level_predicates
      item = build_log_item(level: :info)

      assert_predicate item, :valid?
      assert_predicate item, :valid_level?
      assert_predicate item, :info?
      refute_predicate item, :warning?
      refute_predicate item, :error?
    end

    def test_warning_level_predicates
      item = build_log_item(level: :warning)

      assert_predicate item, :valid?
      assert_predicate item, :warning?
      refute_predicate item, :info?
      refute_predicate item, :error?
    end

    def test_error_level_predicates
      item = build_log_item(level: :error)

      assert_predicate item, :valid?
      assert_predicate item, :error?
      refute_predicate item, :info?
      refute_predicate item, :warning?
    end

    def test_item_returns_full_attribute_hash
      item = Assistant::LogItem.new(level: :info, source: :s, detail: :d, message: 'm', trace: 'trace-data')

      assert_equal({ level: :info, source: :s, detail: :d, message: 'm', trace: 'trace-data' }, item.item)
    end

    def test_trace_defaults_to_nil_and_round_trips_value
      assert_nil build_log_item.trace
      assert_equal %w[a b], build_log_item(trace: %w[a b]).trace
    end

    def test_internal_logging_call_sites_construct_valid_log_items
      service = Class.new(Assistant::Service) do
        input name: :token, type: String, required: true, if: ->(value) { value.start_with?('sk-') }

        def validate
          log_item_info(source: :validate, detail: :started, message: 'started')
          log_item_warning(source: :validate, detail: :slow, message: 'slow')
          log_item_error(source: :validate, detail: :failed, message: 'failed')
        end

        def execute = :ok
      end

      missing = service.run
      conditional = service.run(token: 'pk-bad')
      valid = service.run(token: 'sk-ok')

      assert_equal :with_errors, missing[:status]
      assert_equal :with_errors, conditional[:status]
      assert_equal :with_errors, valid[:status]
    end
  end
end

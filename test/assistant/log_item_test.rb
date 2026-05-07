# frozen_string_literal: true

require_relative '../test_helper'

module Assistant
  class LogItemTest < Minitest::Test
    include TestHelpers::LogItems

    def test_invalid_log_item_with_blank_attributes
      item = Assistant::LogItem.new(level: '', source: '', detail: '', message: '')

      refute_predicate item, :valid?
      refute_predicate item, :valid_level?
      refute_predicate item, :valid_source?
      refute_predicate item, :valid_detail?
      refute_predicate item, :valid_message?
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
  end
end

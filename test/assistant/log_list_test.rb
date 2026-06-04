# frozen_string_literal: true

require_relative '../test_helper'

module Assistant
  class LogListTest < Minitest::Test
    include TestHelpers::LogItems

    def setup
      @host = Class.new(Assistant::Service).new
    end

    def test_add_log_with_empty_arguments_raises_argument_error
      assert_raises(ArgumentError) { @host.add_log }
    end

    def test_add_log_with_invalid_arguments_raises_and_does_not_append
      error = assert_raises(ArgumentError) do
        @host.add_log(level: '', source: '', detail: '', message: '')
      end

      assert_match(/invalid LogItem/, error.message)
      assert_empty @host.logs
    end

    def test_add_log_with_valid_arguments
      result = @host.add_log(level: 'info', source: 'test', detail: 'other test', message: 'hi')

      assert_equal 1, result.size
    end

    def test_infos_returns_only_info_level_logs
      @host.merge_logs(build_log_items(3, level: :info))
      @host.merge_logs(build_log_items(3, level: :warning))

      assert_equal 3, @host.infos.size
    end

    def test_warnings_returns_only_warning_level_logs
      @host.add_log(level: :info, source: :s, detail: :d, message: 'i')
      @host.add_log(level: :warning, source: :s, detail: :d2, message: 'w')
      @host.add_log(level: :warning, source: :s, detail: :d3, message: 'w2')
      @host.add_log(level: :error, source: :s, detail: :d4, message: 'e')

      assert_equal 2, @host.warnings.size
      assert_equal [:warning], @host.warnings.map(&:level).uniq
    end

    def test_errors_returns_only_error_level_logs
      @host.add_log(level: :info, source: :s, detail: :d, message: 'i')
      @host.add_log(level: :error, source: :s, detail: :d2, message: 'e')

      assert_equal 1, @host.errors.size
      assert_equal :error, @host.errors.first.level
    end

    def test_merge_logs_concatenates_foreign_array
      foreign = [
        Assistant::LogItem.new(level: :info, source: :s, detail: :d1, message: 'm1'),
        Assistant::LogItem.new(level: :error, source: :s, detail: :d2, message: 'm2')
      ]
      @host.merge_logs(foreign)

      assert_equal foreign, @host.instance_variable_get(:@logs)
      assert_equal 1, @host.errors.size
    end

    def test_log_item_error_initialize_appends_shaped_error
      @host.log_item_error_initialize(attr_name: :foo, message: 'bad')
      log = @host.errors.first

      assert_equal :error, log.level
      assert_equal :initialize, log.source
      assert_equal :foo, log.detail
      assert_equal 'bad', log.message
    end

    # ---- M5 shorthands: log_item_info / _warning / _error ----

    def test_log_item_info_appends_info_log
      @host.log_item_info(source: :execute, detail: :cache_hit, message: 'ok')
      log = @host.infos.first

      assert_equal :info, log.level
      assert_equal :execute, log.source
      assert_equal :cache_hit, log.detail
      assert_equal 'ok', log.message
    end

    def test_log_item_warning_appends_warning_log
      @host.log_item_warning(source: :execute, detail: :rate_limited, message: 'slow down')
      log = @host.warnings.first

      assert_equal :warning, log.level
      assert_equal :execute, log.source
      assert_equal :rate_limited, log.detail
      assert_equal 'slow down', log.message
    end

    def test_log_item_error_appends_error_log
      @host.log_item_error(source: :execute, detail: :db_unreachable, message: 'down')
      log = @host.errors.first

      assert_equal :error, log.level
      assert_equal :execute, log.source
      assert_equal :db_unreachable, log.detail
      assert_equal 'down', log.message
    end

    def test_log_item_shorthand_returns_logs_array
      result = @host.log_item_info(source: :s, detail: :d, message: 'm')

      assert_same @host.instance_variable_get(:@logs), result
      assert_equal 1, result.size
    end

    def test_log_item_shorthand_accepts_trace
      trace = caller
      @host.log_item_error(source: :execute, detail: :boom, message: 'x', trace: trace)

      assert_equal trace, @host.errors.first.trace
    end
  end
end

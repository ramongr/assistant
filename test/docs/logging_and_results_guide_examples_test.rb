# frozen_string_literal: true

require_relative '../test_helper'

# Integration tests mirroring the runnable examples in
# docs/guides/logging-and-results.md.
class LoggingAndResultsGuideExamplesTest < Minitest::Test
  def test_valid_levels_is_frozen_three_symbol_array
    assert_equal %i[info warning error], Assistant::LogItem::VALID_LEVELS
  end

  class Mixed < Assistant::Service
    input :email, type: String,  required: true
    input :age,   type: Integer, allow_nil: true, default: nil

    def validate
      return if email.include?('@')

      log_item_error(source: :validate, detail: :email, message: 'invalid email')
    end

    def execute
      log_item_info(source: :execute, detail: :age, message: "age=#{age.inspect}")
      log_item_warning(source: :execute, detail: :age, message: 'age missing') if age.nil?

      { id: 42, email:, age: }
    end
  end

  def test_three_helpers_segregate_into_level_buckets
    svc = Mixed.new(email: 'a@b.com')
    svc.run

    assert_equal 1, svc.infos.size
    assert_equal 1, svc.warnings.size
    assert_empty svc.errors
    assert_equal :with_warnings, svc.status
  end

  def test_add_log_with_dynamic_level
    svc = Mixed.new(email: 'a@b.com')
    svc.send(:add_log, level: :warning, source: :execute, detail: :payment, message: 'flaky')

    assert_equal 1, svc.warnings.size
  end

  def test_result_hash_success_shape
    payload = Mixed.run(email: 'a@b.com', age: 30)

    assert_equal :ok, payload.fetch(:status)
    assert_equal({ id: 42, email: 'a@b.com', age: 30 }, payload.fetch(:result))
    assert_empty payload.fetch(:warnings)
  end

  def test_result_hash_failure_shape
    payload = Mixed.run(email: 'oops')

    assert_equal :with_errors, payload.fetch(:status)
    assert_nil payload.fetch(:result)
    refute_empty payload.fetch(:errors)
  end

  def test_pattern_match_consumption_shape
    payload = Mixed.run(email: 'a@b.com', age: 30)

    matched =
      case payload
      in { result:, status: :ok }
        result
      in { result:, status: :with_warnings, warnings: }
        [result, warnings]
      in { errors:, status: :with_errors }
        errors
      end

    assert_equal({ id: 42, email: 'a@b.com', age: 30 }, matched)
  end

  def test_infos_not_part_of_result_hash
    payload = Mixed.run(email: 'a@b.com', age: 30)

    refute_includes payload.keys, :infos
  end

  class Outer < Assistant::Service
    def execute
      merge_logs(logs: [Assistant::LogItem.new(level: :info, source: :outer, detail: :merge, message: 'merged')])
      :done
    end
  end

  def test_merge_logs_keyword_only_appends
    payload = Outer.run

    assert_equal :ok, payload.fetch(:status)
  end

  def test_merge_logs_positional_raises
    svc = Outer.new
    assert_raises(ArgumentError) { svc.merge_logs([]) }
  end

  def test_item_returns_hash_view
    item = Assistant::LogItem.new(level: :error, source: :validate, detail: :email, message: 'invalid')

    assert_equal({ level: :error, source: :validate, detail: :email, message: 'invalid', trace: nil }, item.item)
  end
end

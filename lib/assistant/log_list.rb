# frozen_string_literal: true

# Mixin that gives `Assistant::Service` its log timeline. Owns the
# `@logs` array and exposes the public helpers (`#add_log`, `#merge_logs`,
# the `log_item_*` shorthands, `#infos` / `#warnings` / `#errors`) used
# by service code to record observations and by callers to read the
# result.
module Assistant::LogList
  # Append a single {Assistant::LogItem} to the timeline.
  #
  # @param level   [Symbol] `:info`, `:warning`, or `:error`
  # @param source  [Symbol] subsystem identifier
  # @param detail  [Symbol] sub-identifier (often an attribute name)
  # @param message [String] human-readable message
  # @param trace   [Array<String>, nil] optional backtrace
  # @return [Array<Assistant::LogItem>] the updated timeline
  # @raise [ArgumentError] if {Assistant::LogItem#initialize} rejects the inputs
  def add_log(level:, source:, detail:, message:, trace: nil)
    @logs << Assistant::LogItem.new(level:, source:, detail:, message:, trace:)
  end

  # Concatenate an existing log timeline onto this service's `@logs`,
  # preserving insertion order. Used by `Service#call_service` (M-S2).
  #
  # @param logs [Array<Assistant::LogItem>] entries to append
  # @return [Array<Assistant::LogItem>] the updated timeline
  def merge_logs(logs:)
    @logs.concat(logs)
  end

  # Convenience used by InputBuilder-generated validators to record an
  # initialization-time error for a specific input attribute.
  #
  # @param attr_name [Symbol] the offending input name (recorded as `detail`)
  # @param message   [String] human-readable explanation
  # @return [Array<Assistant::LogItem>] the updated timeline
  def log_item_error_initialize(attr_name:, message:)
    @logs << Assistant::LogItem.new(detail: attr_name, level: :error, message:, source: :initialize)
  end

  ::Assistant::LogItem::VALID_LEVELS.each do |level|
    define_method("#{level}s") do
      @logs.select { |log| log.send("#{level}?") }
    end

    # Shorthand: log_item_info / log_item_warning / log_item_error.
    # See docs/v1/index.md M5.
    define_method("log_item_#{level}") do |source:, detail:, message:, trace: nil|
      add_log(level:, source:, detail:, message:, trace:)
    end
  end
end

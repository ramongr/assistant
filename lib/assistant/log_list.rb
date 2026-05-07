# frozen_string_literal: true

module Assistant
  # Service level list of logs
  module LogList
    def add_log(level:, source:, detail:, message:, trace: nil)
      @logs << Assistant::LogItem.new(level:, source:, detail:, message:, trace:)
    end

    def merge_logs(other_logs)
      @logs.concat(other_logs)
    end

    # Convenience used by InputBuilder-generated validators to record an
    # initialization-time error for a specific input attribute.
    def log_item_error_initialize(attr_name:, message:)
      @logs << Assistant::LogItem.new(detail: attr_name, level: :error, message:, source: :initialize)
    end

    ::Assistant::LogItem::VALID_LEVELS.each do |level|
      define_method("#{level}s") do
        @logs.select { |log| log.send("#{level}?") }
      end
    end
  end
end

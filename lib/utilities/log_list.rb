# frozen_string_literal: true

module Utilities
  # Service level list of logs
  module LogList
    def add_log(level:, source:, detail:, message:, trace: nil)
      @logs << Assistant::LogItem.new(level:, source:, detail:, message:, trace:)
    end

    def merge_logs(other_logs)
      @logs.concat(other_logs)
    end

    ::Assistant::LogItem::VALID_LEVELS.each do |level|
      define_method("#{level}s") do
        @logs.select { |log| log.send("#{level}?") }
      end
    end
  end
end

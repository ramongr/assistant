# frozen_string_literal: true

module Assistant
  module Utilities
    # Service level list of logs
    module LogList
      def add_log(level:, source:, detail:, message:, trace: nil)
        @logs << Assistant::LogItem.new(level: level, source: source, detail: detail, message: message, trace: trace)
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
end

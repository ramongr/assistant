# frozen_string_literal: true

module Assistant
  # Log base class
  class LogItem
    VALID_LEVELS = %i[info warning error].freeze

    attr_reader :level, :source, :detail, :message, :trace

    def initialize(level:, source:, detail:, message:, trace: nil)
      @level = level.to_sym
      @source = source.to_sym
      @detail = detail.to_sym
      @message = message.to_s
      @trace = trace
    end

    def valid?
      [valid_level?, valid_source?, valid_detail?, valid_message?].all?
    end

    def item
      { level: level, source: source, detail: detail, message: message, trace: trace }
    end

    VALID_LEVELS.each do |valid_level|
      # info? warning? error?
      define_method("#{valid_level}?") do
        level == valid_level
      end
    end

    def valid_level?
      VALID_LEVELS.include?(level)
    end

    def valid_source?
      source.size.positive? && detail != source
    end

    def valid_detail?
      detail.size.positive? && source != detail
    end

    def valid_message?
      message.size.positive?
    end
  end
end

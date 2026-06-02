# frozen_string_literal: true

module Assistant
  # Log base class
  class LogItem
    VALID_LEVELS = %i[info warning error].freeze

    attr_reader :level, :source, :detail, :message, :trace

    def initialize(level:, source:, detail:, message:, trace: nil)
      @level = normalize_symbol(level)
      @source = normalize_symbol(source)
      @detail = normalize_symbol(detail)
      @message = message.to_s
      @trace = trace
      validate!
    end

    def valid?
      [valid_level?, valid_source?, valid_detail?, valid_message?].all?
    end

    def item
      { level:, source:, detail:, message:, trace: }
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
      present_log_attribute?(source) && detail != source
    end

    def valid_detail?
      present_log_attribute?(detail) && source != detail
    end

    def valid_message?
      message.size.positive?
    end

    private

    def validate!
      return if valid?

      raise ArgumentError, "invalid LogItem: #{validation_errors.join('; ')}"
    end

    def validation_errors
      errors = []
      errors << "level must be one of [#{VALID_LEVELS.join(', ')}]" unless valid_level?
      errors << 'source must be present and different from detail' unless valid_source?
      errors << 'detail must be present and different from source' unless valid_detail?
      errors << 'message must be present' unless valid_message?
      errors
    end

    def normalize_symbol(value)
      value.respond_to?(:to_sym) ? value.to_sym : value
    end

    def present_log_attribute?(value)
      value.respond_to?(:size) && value.size.positive?
    end
  end
end

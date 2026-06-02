# frozen_string_literal: true

module Assistant
  # Log base class
  class LogItem
    VALID_LEVELS = %i[info warning error].freeze
    ERRORS = [
      ["level must be one of [#{VALID_LEVELS.join(', ')}]", :valid_level?],
      ['source must be present and different from detail', :valid_source?],
      ['detail must be present and different from source', :valid_detail?],
      ['message must be present', :valid_message?]
    ].freeze

    attr_reader :level, :source, :detail, :message, :trace

    def initialize(level:, source:, detail:, message:, trace: nil)
      @level = normalize_symbol(level)
      @source = normalize_symbol(source)
      @detail = normalize_symbol(detail)
      @message = message.to_s
      @trace = trace
      validate!
    end

    def valid? = [valid_level?, valid_source?, valid_detail?, valid_message?].all?

    def item
      { level:, source:, detail:, message:, trace: }
    end

    VALID_LEVELS.each do |valid_level|
      # info? warning? error?
      define_method("#{valid_level}?") do
        level == valid_level
      end
    end

    def valid_level? = VALID_LEVELS.include?(level)

    def valid_source? = present_log_attribute?(source) && detail != source

    def valid_detail? = present_log_attribute?(detail) && source != detail

    def valid_message? = !message.strip.empty?

    private

    def validate!
      errors = validation_errors
      return if errors.empty?

      raise ArgumentError, "invalid LogItem: #{errors.join('; ')}"
    end

    def validation_errors = ERRORS.reject { |_, validation_method| send(validation_method) }.map(&:first)

    def normalize_symbol(value)
      value.respond_to?(:to_sym) ? value.to_sym : value
    end

    def present_log_attribute?(value)
      value.respond_to?(:size) && value.size.positive?
    end
  end
end

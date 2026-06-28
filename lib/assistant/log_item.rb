# frozen_string_literal: true

module Assistant
  # A single structured log entry produced by `Service` (directly via
  # `LogList#add_log` or through one of the `log_item_*` shorthands).
  # Construction is **strict** since 1.0 (M10): invalid attributes raise
  # `ArgumentError` rather than producing an instance whose `#valid?`
  # returns `false`. See `docs/v1/index.md` for the
  # rationale.
  #
  # @example Build an error log entry
  #   Assistant::LogItem.new(
  #     level: :error,
  #     source: :create_user,
  #     detail: :email,
  #     message: 'must not be blank'
  #   )
  class LogItem
    # The exhaustive set of accepted `level:` values, in display order.
    # @return [Array<Symbol>]
    VALID_LEVELS = %i[info warning error].freeze

    # Validation rules applied in `#initialize`. Each entry pairs a
    # human message with the predicate that must hold. Internal.
    # @api private
    ERRORS = [
      ["level must be one of [#{VALID_LEVELS.join(', ')}]", :valid_level?],
      ['source must be present and different from detail', :valid_source?],
      ['detail must be present and different from source', :valid_detail?],
      ['message must be present', :valid_message?]
    ].freeze

    # @return [Symbol] severity (`:info`, `:warning`, or `:error`)
    # @!attribute [r] level
    # @return [Symbol] high-level subsystem the entry came from (e.g. `:initialize`, `:hook`)
    # @!attribute [r] source
    # @return [Symbol] finer-grained detail under `source` (often an attribute name)
    # @!attribute [r] detail
    # @return [String] human-readable message
    # @!attribute [r] message
    # @return [Array<String>, nil] optional backtrace captured at construction
    # @!attribute [r] trace
    attr_reader :level, :source, :detail, :message, :trace

    # @param level   [Symbol, #to_sym] one of {VALID_LEVELS}
    # @param source  [Symbol, #to_sym] subsystem identifier; must differ from `detail`
    # @param detail  [Symbol, #to_sym] sub-identifier; must differ from `source`
    # @param message [#to_s] human-readable message; must not be blank
    # @param trace   [Array<String>, nil] optional backtrace
    # @raise [ArgumentError] when any of the constructor checks in {ERRORS} fail
    def initialize(level:, source:, detail:, message:, trace: nil)
      @level = normalize_symbol(level)
      @source = normalize_symbol(source)
      @detail = normalize_symbol(detail)
      @message = message.to_s
      @trace = trace
      validate!
    end

    # @return [Boolean] always `true` for instances constructed via {#initialize} (which raises on invalid input).
    #   Retained for introspection and downstream tooling.
    def valid? = [valid_level?, valid_source?, valid_detail?, valid_message?].all?

    # @return [Hash{Symbol => Object}] hash view with keys `:level`, `:source`, `:detail`, `:message`, `:trace`
    def item
      { level:, source:, detail:, message:, trace: }
    end

    VALID_LEVELS.each do |valid_level|
      # info? warning? error?
      define_method("#{valid_level}?") do
        level == valid_level
      end
    end

    # @return [Boolean] true when `level` is one of {VALID_LEVELS}
    def valid_level? = VALID_LEVELS.include?(level)

    # @return [Boolean] true when `source` is non-empty and not equal to `detail`
    def valid_source? = present_log_attribute?(source) && detail != source

    # @return [Boolean] true when `detail` is non-empty and not equal to `source`
    def valid_detail? = present_log_attribute?(detail) && source != detail

    # @return [Boolean] true when `message` contains at least one non-whitespace character
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

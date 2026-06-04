# frozen_string_literal: true

require_relative 'execute_callbacks'
require_relative 'input_builder'
require_relative 'log_list'

module Assistant
  # Core Service base class. Subclasses declare inputs via the
  # InputBuilder DSL, optionally register before/after/around execute
  # hooks via ExecuteCallbacks, and implement `#execute`.
  class Service # rubocop:disable Metrics/ClassLength
    include Assistant::LogList

    # Public reader for the full log timeline (info + warning + error), in
    # insertion order. See docs/v1/02-features.md M4.
    attr_reader :logs

    class << self
      include Assistant::InputBuilder
      include Assistant::ExecuteCallbacks

      def run(**)
        new(**).run
      end
    end

    def initialize(**args)
      @inputs = args
      apply_input_defaults
      @logs = []
    end

    def run
      @run_started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      notify(:service_started)

      validate_inputs
      validate
      notify(:service_validated)

      return failed_payload if errors.any?

      # Trigger `#execute` (through the M-S1 hook chain) eagerly so any
      # error logged by a `before_/after_/around_execute` hook influences
      # the terminal event and the payload's `:status` field.
      result
      errors.empty? ? executed_payload : failed_payload
    end

    def result
      @result ||= run_execute_with_callbacks
    end

    def success?
      errors.empty?
    end

    def failure?
      errors.any?
    end

    def status
      warnings.empty? ? :ok : :with_warnings
    end

    private

    # Build the success-path result hash and fire the terminal
    # `:service_executed` event. Triggers `#execute` lazily via `#result`.
    def executed_payload
      payload = { result:, status:, warnings: }
      notify(:service_executed)
      payload
    end

    # Build the failure-path result hash and fire the terminal
    # `:service_failed` event. Does not invoke `#execute`.
    def failed_payload
      payload = { errors:, result: nil, status: :with_errors }
      notify(:service_failed)
      payload
    end

    # M1: apply input defaults declared via `input :name, default: ...`.
    # A default fires when the key is absent, or when the value is an
    # explicit `nil` and the input is not `allow_nil: true` (M2). Procs
    # are invoked with no arguments (zero-arity enforced at
    # class-definition time); literals are used as-is. Defaulted values
    # are subject to the same type / required / if validation as
    # caller-supplied values.
    def apply_input_defaults
      input_definitions_needing_default.each do |attr_name, options|
        provider = options[:default]
        @inputs[attr_name] = provider.is_a?(Proc) ? provider.call : provider
      end
    end

    # Input definitions that declare a `:default` and whose key was not
    # already supplied by the caller (with `allow_nil:` honoured).
    def input_definitions_needing_default
      self.class.input_definitions.select do |attr_name, options|
        options.key?(:default) && !input_supplied?(attr_name, options)
      end
    end

    # An explicit nil counts as "not supplied" so the default fires,
    # unless the input opted into `allow_nil: true` — in which case the
    # caller's nil is honoured and the default is skipped.
    def input_supplied?(attr_name, options)
      @inputs.key?(attr_name) && (options[:allow_nil] == true || !@inputs[attr_name].nil?)
    end

    def validate_inputs
      # M9: regex matches only the canonical `valid_required_*?` /
      # `valid_required_conditional_*?` / `valid_type_*?` predicates so
      # the deprecated `valid_require_*?` aliases are not auto-invoked
      # (which would emit the M9 deprecation warning from inside the
      # framework itself).
      methods.grep(/valid_(required|type)_\w+\?$/).each do |validation_method|
        send(validation_method)
      end
    end

    # M-S3: dispatch a frozen-set instrumentation event to the configured
    # `Assistant.notifier`. Payload always includes `:service_class` and
    # `:duration_s` (Float seconds since the start of `#run`). The notifier
    # is treated as untrusted infra: any `StandardError` it raises is
    # caught and surfaced via `Kernel.warn` so a misconfigured notifier
    # cannot tear down every service in the process. Non-`StandardError`
    # exceptions (e.g. `SystemExit`, `Interrupt`) are intentionally
    # allowed to propagate.
    def notify(event)
      duration_s = Process.clock_gettime(Process::CLOCK_MONOTONIC) - @run_started_at
      Assistant.notifier.call(event, { service_class: self.class, duration_s: duration_s })
    rescue StandardError => e
      Kernel.warn "assistant: notifier raised during #{event} for #{self.class}: #{e.class}: #{e.message}"
    end

    # M-S1: thread `#execute` through the registered before/around/after
    # hook chains. Called once via `#result`'s memoization, so each
    # service instance runs hooks at most once even if `#result` is
    # invoked repeatedly.
    def run_execute_with_callbacks
      run_before_execute_hooks
      result = run_around_execute_chain
      run_after_execute_hooks(result)
      result
    end

    # M-S1: invoke every registered `before_execute` hook in declaration
    # order. Each hook is independent — a `StandardError` from one is
    # logged via `add_log(level: :error, source: :hook, …)` and the
    # remaining hooks still fire.
    def run_before_execute_hooks
      self.class.before_execute_hooks.each do |hook|
        hook.bind_call(self)
      rescue StandardError => e
        log_hook_error(:before_execute, e)
      end
    end

    # M-S1: invoke every registered `after_execute` hook in declaration
    # order, passing the execute result as the single positional arg.
    def run_after_execute_hooks(execute_result)
      self.class.after_execute_hooks.each do |hook|
        hook.bind_call(self, execute_result)
      rescue StandardError => e
        log_hook_error(:after_execute, e)
      end
    end

    # M-S1: build the around-hook chain from the innermost layer (the
    # raw `#execute` call) outwards. Declaration order wraps: the
    # first-declared hook is the outermost layer. If an around hook
    # raises before yielding to its continuation, that layer (and any
    # inner layers, including `#execute` itself) does not run; the
    # layer returns `nil` and outer hooks still wrap normally.
    def run_around_execute_chain
      chain = -> { execute }
      self.class.around_execute_hooks.reverse_each do |hook|
        chain = wrap_around_layer(hook, chain)
      end
      chain.call
    end

    # Build a single around layer: a lambda that runs `hook` with
    # `inner` as its continuation. Hook exceptions raised before the
    # continuation runs are caught, logged, and the layer returns nil.
    def wrap_around_layer(hook, inner)
      lambda do
        hook.bind_call(self, &inner)
      rescue StandardError => e
        log_hook_error(:around_execute, e)
        nil
      end
    end

    # M-S1: shared hook-error logger. Stamps `source: :hook` and uses
    # the hook type as `detail:` so callers can grep their log timeline
    # by either field. The exception's backtrace is preserved on the
    # `LogItem#trace` field for downstream diagnostics.
    def log_hook_error(hook_type, exception)
      add_log(
        level: :error,
        source: :hook,
        detail: hook_type,
        message: "#{exception.class}: #{exception.message}",
        trace: exception.backtrace
      )
    end

    attr_reader :inputs

    def execute; end

    def validate; end
  end
end

# frozen_string_literal: true

require_relative 'execute_callbacks'
require_relative 'input_builder'
require_relative 'log_list'

module Assistant
  # Core Service base class. Subclasses declare inputs via the
  # InputBuilder DSL, optionally register before/after/around execute
  # hooks via ExecuteCallbacks, and implement `#execute`.
  #
  # @example Minimal service
  #   class Greet < Assistant::Service
  #     input :name, type: String, required: true
  #
  #     def execute
  #       "Hello, #{name}!"
  #     end
  #   end
  #
  #   Greet.run(name: 'Ada')
  #   # => { result: "Hello, Ada!", status: :ok, warnings: [] }
  class Service # rubocop:disable Metrics/ClassLength
    include Assistant::LogList

    # Public reader for the full log timeline (info + warning + error), in
    # insertion order. See docs/v1/index.md M4.
    #
    # @return [Array<Assistant::LogItem>]
    attr_reader :logs

    class << self
      include Assistant::InputBuilder
      include Assistant::ExecuteCallbacks

      # Convenience: build a service with the given keyword arguments
      # and immediately invoke `#run`, returning the result hash.
      # Equivalent to `new(**inputs).run`.
      #
      # @return [Hash] the result payload — see {Service#run}
      def run(**)
        new(**).run
      end

      # M-S4: per-subclass `Data` class whose members are the declared
      # input names, in declaration order. Memoised on the subclass and
      # transparently rebuilt if `input_definitions` changes (e.g. a
      # late `input :foo` after the first snapshot call). Used by
      # `Service#input_snapshot`; users normally never touch it.
      #
      # @return [Class] a `Data.define` subclass
      def input_snapshot_class
        keys = input_definitions.keys
        return @input_snapshot_class if @input_snapshot_class && @input_snapshot_class_keys == keys

        @input_snapshot_class_keys = keys
        @input_snapshot_class = Data.define(*keys)
      end
    end

    # @param args [Hash] keyword arguments matching the declared inputs.
    #   Unknown keys are accepted but excluded from {#input_snapshot}.
    def initialize(**args)
      @inputs = args
      apply_input_defaults
      @logs = []
    end

    # Execute the validation + execute pipeline and return the result
    # payload. Fully idempotent: every subsequent call returns the same
    # cached payload without re-running validations, hooks, or
    # `#execute`. Only the first call performs side-effects.
    #
    # @return [Hash{Symbol => Object}] either
    #   - `{ result: Object, status: :ok | :with_warnings, warnings: Array<LogItem> }`
    #     on success, or
    #   - `{ errors: Array<LogItem>, result: nil, status: :with_errors }`
    #     when any error has been logged before or during validation.
    def run
      return @ran_payload if defined?(@ran_payload)

      @run_started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      notify(:service_started)

      validate_inputs
      validate
      notify(:service_validated)

      return @ran_payload = failed_payload if errors.any?

      # Trigger `#execute` (through the M-S1 hook chain) eagerly so any
      # error logged by a `before_/after_/around_execute` hook influences
      # the terminal event and the payload's `:status` field.
      result
      @ran_payload = errors.empty? ? executed_payload : failed_payload
    end

    # Memoised return value of {#execute}, threaded through the
    # registered before/around/after execute hooks (M-S1).
    #
    # @return [Object] whatever the subclass's `#execute` returned
    def result
      @result ||= run_execute_with_callbacks
    end

    # @return [Boolean] true when no `:error` entries have been logged
    def success?
      errors.empty?
    end

    # @return [Boolean] true when at least one `:error` entry has been logged
    def failure?
      errors.any?
    end

    # Terminal status for the success path. Failure runs use
    # `:with_errors` directly in the result payload (see {#run}).
    #
    # @return [Symbol] `:ok` when there are no warnings, otherwise `:with_warnings`
    def status
      warnings.empty? ? :ok : :with_warnings
    end

    # M-S2: instantiate `klass`, run it, merge its log timeline into the
    # current service, and return the inner service instance.
    #
    # The full log timeline of the inner service (info + warning +
    # error) is concatenated onto the outer service's `@logs` via
    # `merge_logs`. Because the outer service's `errors`, `warnings`,
    # and `status` are derived by filtering `@logs`, an inner error
    # automatically downgrades the outer terminal status to
    # `:with_errors`, and inner warnings surface as `:with_warnings`
    # when no errors are present — without any special handling in
    # the caller.
    #
    # The returned inner instance exposes `#result`, `#success?`,
    # `#failure?`, etc. so the caller can branch on the inner outcome:
    #
    # @example
    #   def execute
    #     other = call_service(OtherService, foo: 1)
    #     return if failure?
    #     other.result + 1
    #   end
    #
    # `call_service` does **not** rescue exceptions raised by the inner
    # service's `#execute` or by `Assistant.notifier`; those propagate
    # to the caller, matching the base `Service#run` contract. To run
    # an inner service that may raise, wrap the call in a `begin/rescue`
    # and use `add_log(level: :error, …)` to record the failure.
    #
    # @param klass  [Class<Assistant::Service>] the inner service class
    # @param inputs [Hash] keyword arguments forwarded to `klass.new`
    # @return [Assistant::Service] the inner service instance, already run
    # @raise [ArgumentError] if `klass` is not a subclass of {Assistant::Service}
    def call_service(klass, **inputs)
      unless klass.is_a?(Class) && klass <= Assistant::Service
        raise ArgumentError, "call_service expects an Assistant::Service subclass, got #{klass.inspect}"
      end

      inner = klass.new(**inputs)
      inner.run
      merge_logs(logs: inner.logs)
      inner
    end

    # M-S4: a read-only `Data` view over the declared inputs of this
    # service, post-`default:` / post-`allow_nil:`. Members are the
    # input names declared via `Service.input` / `Service.inputs`, in
    # declaration order; values are read from `@inputs` after
    # `apply_input_defaults` has run, so callers see the same values
    # the per-input getters expose.
    #
    # @example
    #   class Greet < Assistant::Service
    #     input :name, type: String, required: true
    #     input :loud, type: TrueClass, default: false
    #   end
    #
    #   Greet.new(name: 'Ada').input_snapshot
    #   # => #<data name="Ada", loud=false>
    #
    # The returned object is a `Data` instance, so it is structurally
    # immutable: no member can be reassigned. Member values that are
    # themselves mutable (e.g. an `Array` passed as an input) keep
    # their normal mutability — the snapshot does not deep-freeze.
    #
    # Only declared inputs appear in the snapshot. Extra keyword
    # arguments accepted by `#initialize` (which live in `@inputs`
    # but have no `input :foo` declaration) are intentionally excluded
    # so the snapshot's shape matches the public DSL.
    #
    # A declared input with no default and no caller-supplied value
    # appears with a `nil` member value, mirroring the behaviour of
    # the per-input getter.
    #
    # @return [Data] read-only view over `input_definitions.keys`
    def input_snapshot
      keys = self.class.input_definitions.keys
      self.class.input_snapshot_class.new(**keys.to_h { |name| [name, @inputs[name]] })
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

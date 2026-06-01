# frozen_string_literal: true

require_relative 'input_builder'
require_relative 'log_list'

module Assistant
  # Base class for the Assistant gem
  class Service
    include Assistant::LogList

    # Public reader for the full log timeline (info + warning + error), in
    # insertion order. See docs/v1/02-features.md M4.
    attr_reader :logs

    class << self
      include Assistant::InputBuilder

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
      validate_inputs
      validate

      if errors.empty?
        { result:, status:, warnings: }
      else
        { errors:, result: nil, status: :with_errors }
      end
    end

    def result
      @result ||= execute
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
      methods.grep(/valid_(require|type|require_conditional)_\w+\?$/).each do |validation_method|
        send(validation_method)
      end
    end

    attr_reader :inputs

    def execute; end

    def validate; end
  end
end

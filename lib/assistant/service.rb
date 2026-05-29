# frozen_string_literal: true

require_relative 'input_builder'
require_relative 'log_list'

module Assistant
  # Base class for the Assistant gem
  class Service
    include LogList

    class << self
      include InputBuilder

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
    # Walks input_definitions in declaration order. A default fires when the
    # key is absent OR the value is an explicit nil. Procs are invoked with
    # no arguments (zero-arity enforced at class-definition time); literals
    # are used as-is. Defaulted values are subject to the same type / required
    # / if validation as caller-supplied values.
    def apply_input_defaults
      self.class.input_definitions.each do |attr_name, defn|
        next unless defn.key?(:default)
        next if @inputs.key?(attr_name) && !@inputs[attr_name].nil?

        provider = defn[:default]
        @inputs[attr_name] = provider.is_a?(Proc) ? provider.call : provider
      end
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

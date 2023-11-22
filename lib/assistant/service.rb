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
      @logs = []
      @keys = []
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

    def validate_inputs
      methods.grep(/valid_(require|type|require_conditional)_[\w]+\?$/).each do |validation_method|
        send(validation_method)
      end
    end

    attr_reader :inputs

    def execute; end

    def validate; end
  end
end

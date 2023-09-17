# frozen_string_literal: true

require_relative './input_validation'
require_relative '../utilities/log_list'

require 'byebug'

module Assistant
  # Base class for the Assistant gem
  class Service
    include ::Utilities::LogList

    class << self
      include Assistant::InputSetter

      def run(**args)
        new(**args).run
      end
    end

    def initialize(**args)
      @inputs = args
      @logs = []
    end

    def run
      validate_inputs
      validate
      if errors.empty?
        { result: execute, status:, warnings: }
      else
        { result: execute, status: :with_errors, errors: @logs }
      end
    end

    def status
      warnings.empty? ? :ok : :with_warnings
    end

    def validate_inputs = @inputs.each { |input, _| send("valid_#{input}?") }

    protected

    attr_reader :inputs

    def execute; end

    def validate; end
  end
end

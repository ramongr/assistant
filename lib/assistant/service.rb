# frozen_string_literal: true

require_relative 'input/builder'
require_relative 'log_list'

module Assistant
  # Base class for the Assistant gem
  class Service
    include LogList

    class << self
      include Assistant::Input::Builder

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
      defaults
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

    def defaults
      method_names = @inputs.keys.map { |key| :"set_attributes_#{key}" }
      byebug
      (method_names & methods).each do |set_attribute_method|
        send(set_attribute_method)
      end
    end

    def validate_inputs
      methods.grep(/valid_(default|require|type|require_conditional)_[\w_]+\?$/).each do |validation_method|
        send(validation_method)
      end
    end

    attr_reader :inputs

    def execute; end

    def validate; end
  end
end

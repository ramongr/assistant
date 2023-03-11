# frozen_string_literal: true

module Assistant
  # Base class for the Assistant gem
  class Service
    include ::Assistant::LogList

    def initialize(*args)
      @inputs = args
      @logs = []
    end

    def run
      validate
      { result: execute, status: define_status, warnings: warnings } if errors.size.empty?
    end

    def define_status
      warnings.size.empty? ? :ok : :with_warnings
    end

    protected

    def execute; end

    def validate; end
  end
end

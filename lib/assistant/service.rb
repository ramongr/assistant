# frozen_string_literal: true

module Assistant
  # Base class for the Assistant gem
  class Service
    include ::Assistant::LogList

    class << self
      def run(*args)
        new(*args).run
      end
    end

    def initialize(*args)
      @inputs = args
      @logs = []
    end

    def run
      validate
      { result: execute, status: status, warnings: warnings } if errors.empty?
    end

    def status
      warnings.empty? ? :ok : :with_warnings
    end

    protected

    def execute; end

    def validate; end
  end
end

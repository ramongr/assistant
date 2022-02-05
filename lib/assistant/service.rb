# frozen_string_literal: true

module Assistant
  # Base class for the Assistant gem
  class Service
    def initialize(*args)
      @inputs = args
    end

    def run
      execute
    end

    protected

    def execute; end
  end
end

# frozen_string_literal: true

require_relative '../utilities/input_access'
require_relative '../utilities/log_list'

module Assistant
  # Base class for the Assistant gem
  class Service
    include Utilities::LogList

    class << self
      include Utilities::InputAccess

      def run(**args)
        create_reader_methods(args)
        create_presence_methods(args)
        new(args).run
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

# frozen_string_literal: true

module Assistant
  module Utilities
    # Transforms input attributes into simple getter and presence check methods
    module InputAccess
      def create_reader_methods(args)
        args.each_key do |key|
          define_method(key) do
            @inputs[key]
          end
        end
      end

      def create_presence_methods(args)
        args.each_key do |key|
          define_method("#{key}_present?") do
            @inputs.key?(key)
          end
        end
      end
    end
  end
end

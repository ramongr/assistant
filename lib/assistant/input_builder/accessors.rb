# frozen_string_literal: true

require 'assistant/refinements/string_blankness'

module Assistant
  module InputBuilder
    # Generators for the per-input reader and `?`-checker instance methods.
    # The lexical refinement `Assistant::Refinements::StringBlankness` is
    # activated here only (narrower than the pre-M13 module-wide `using`).
    module Accessors
      using Assistant::Refinements::StringBlankness

      def input_getter_meth(attr_name)
        define_method(attr_name) do
          @inputs[attr_name]
        end
      end

      def input_checker_meth(attr_name)
        define_method("#{attr_name}?") do
          val = @inputs[attr_name]
          return false if val.nil? || val == false
          return !val.whitespace? if val.is_a?(String)

          val.respond_to?(:empty?) ? !val.empty? : true
        end
      end
    end
  end
end

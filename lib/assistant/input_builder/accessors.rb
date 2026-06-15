# frozen_string_literal: true

require 'assistant/refinements/string_blankness'

# Generators for the per-input reader and `?`-checker instance methods.
# The lexical refinement `Assistant::Refinements::StringBlankness` is
# activated here only (narrower than the pre-M13 module-wide `using`).
module Assistant::InputBuilder::Accessors
  using Assistant::Refinements::StringBlankness

  # Define `#name` reader on the host class. Returns the raw value
  # stored under `@inputs[name]`.
  #
  # @param name [Symbol] input name
  # @return [void]
  def input_getter_meth(name:)
    define_method(name) do
      @inputs[name]
    end
  end

  # Define `#name?` predicate on the host class. Treats `nil`, `false`,
  # whitespace-only strings, and `#empty?` collections as missing.
  #
  # @param name [Symbol] input name
  # @return [void]
  def input_checker_meth(name:)
    define_method("#{name}?") do
      val = @inputs[name]
      return false if val.nil? || val == false
      return !val.whitespace? if val.is_a?(String)

      val.respond_to?(:empty?) ? !val.empty? : true
    end
  end
end

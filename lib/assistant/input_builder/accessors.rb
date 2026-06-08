# frozen_string_literal: true

require 'assistant/refinements/string_blankness'

# Generators for the per-input reader and `?`-checker instance methods.
# The lexical refinement `Assistant::Refinements::StringBlankness` is
# activated here only (narrower than the pre-M13 module-wide `using`).
module Assistant::InputBuilder::Accessors
  using Assistant::Refinements::StringBlankness

  def input_getter_meth(name:)
    define_method(name) do
      @inputs[name]
    end
  end

  def input_checker_meth(name:)
    define_method("#{name}?") do
      val = @inputs[name]
      return false if val.nil? || val == false
      return !val.whitespace? if val.is_a?(String)

      val.respond_to?(:empty?) ? !val.empty? : true
    end
  end
end

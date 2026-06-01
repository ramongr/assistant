# frozen_string_literal: true

# Refines String with `#whitespace?`, true when a string is empty or
# contains only whitespace characters. Used by `InputBuilder` validators
# to treat whitespace-only strings as missing input without depending on
# ActiveSupport's `String#blank?`.
module Assistant::Refinements::StringBlankness
  refine String do
    # True when the string is empty or contains only whitespace.
    def whitespace?
      strip.empty?
    end
  end
end

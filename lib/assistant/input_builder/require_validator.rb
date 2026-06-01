# frozen_string_literal: true

# Generators for the per-input `valid_require_<name>?` and
# `valid_require_conditional_<name>?` validators. Reads `:required`,
# `:allow_nil` (M2), and `:if` from the input options.
module Assistant::InputBuilder::RequireValidator
  def input_require_validator_meth(attr_name, **options)
    allow_nil = options.fetch(:allow_nil, false) == true

    define_method("valid_require_#{attr_name}?") do |log = true|
      # M2: explicit nil counts as "supplied" when allow_nil: true is set.
      return true if allow_nil && @inputs.key?(attr_name)
      return true if options[:required] == true && send("#{attr_name}?") == true

      log && send(
        :log_item_error_initialize, attr_name:, message: "Service is missing argument with name #{attr_name}"
      )
      false
    end
  end

  def input_require_conditional_meth(attr_name, **options)
    define_method("valid_require_conditional_#{attr_name}?") do
      return false if send("valid_require_#{attr_name}?", false) == false
      return true if options[:if].call(send(attr_name))

      send(
        :log_item_error_initialize,
        attr_name:,
        message: "Service argument conditional requirement not met properly for #{attr_name}"
      )
      false
    end
  end
end

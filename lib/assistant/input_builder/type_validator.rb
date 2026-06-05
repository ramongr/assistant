# frozen_string_literal: true

# Generators for the per-input `valid_type_<name>?` validator (M3:
# multi-type accepted; M2: `allow_nil:` short-circuits the check).
module Assistant::InputBuilder::TypeValidator
  def input_type_validator_meth(name:, type:, **options)
    allow_nil = options.fetch(:allow_nil, false) == true
    types = Array(type)
    message_builder = type_mismatch_message_builder(name:, types:)
    body = type_validator_body(name:, types:, allow_nil:, message_builder:)

    define_method("valid_type_#{name}?", &body)
  end

  # Builds the Proc body for the per-input valid_type_<name>? method.
  # Extracted to keep input_type_validator_meth under metric limits.
  def type_validator_body(name:, types:, allow_nil:, message_builder:)
    lambda do
      value = @inputs[name]
      # M2: when allow_nil: true is set, any supplied key short-circuits
      # the type check (mirrors the require validator's behaviour).
      next true if allow_nil && @inputs.key?(name)
      next true if types.any? { |klass| value.is_a?(klass) }

      send("#{name}?") &&
        send(:log_item_error_initialize, attr_name: name, message: message_builder.call(send(name).class))
      false
    end
  end

  # Returns a Proc that, given the actual class of a failing input,
  # produces the error message. Single-type keeps the original 0.1.0
  # wording for back-compat; multi-type uses "is not one of […]". (M3)
  def type_mismatch_message_builder(name:, types:)
    if types.size == 1
      ->(actual) { "Service argument with name #{name} is not a #{types.first} but #{actual}" }
    else
      ->(actual) { "Service argument with name #{name} is not one of [#{types.join(', ')}] but #{actual}" }
    end
  end
end

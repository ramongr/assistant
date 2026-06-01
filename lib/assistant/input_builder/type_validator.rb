# frozen_string_literal: true

module Assistant
  module InputBuilder
    # Generators for the per-input `valid_type_<name>?` validator (M3:
    # multi-type accepted; M2: `allow_nil:` short-circuits the check).
    module TypeValidator
      def input_type_validator_meth(attr_name, type, **options)
        allow_nil = options.fetch(:allow_nil, false) == true
        types = Array(type)
        message_builder = type_mismatch_message_builder(attr_name, types)
        body = type_validator_body(attr_name, types, allow_nil, message_builder)

        define_method("valid_type_#{attr_name}?", &body)
      end

      # Builds the Proc body for the per-input valid_type_<name>? method.
      # Extracted to keep input_type_validator_meth under metric limits.
      def type_validator_body(attr_name, types, allow_nil, message_builder)
        lambda do
          value = @inputs[attr_name]
          # M2: when allow_nil: true is set, any supplied key short-circuits
          # the type check (mirrors the require validator's behaviour).
          next true if allow_nil && @inputs.key?(attr_name)
          next true if types.any? { |klass| value.is_a?(klass) }

          send("#{attr_name}?") &&
            send(:log_item_error_initialize, attr_name:, message: message_builder.call(send(attr_name).class))
          false
        end
      end

      # Returns a Proc that, given the actual class of a failing input,
      # produces the error message. Single-type keeps the original 0.1.0
      # wording for back-compat; multi-type uses "is not one of […]". (M3)
      def type_mismatch_message_builder(attr_name, types)
        if types.size == 1
          ->(actual) { "Service argument with name #{attr_name} is not a #{types.first} but #{actual}" }
        else
          ->(actual) { "Service argument with name #{attr_name} is not one of [#{types.join(', ')}] but #{actual}" }
        end
      end
    end
  end
end

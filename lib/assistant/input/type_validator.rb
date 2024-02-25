# frozen_string_literal: true

module Assistant
  module Input
    # Type validator method to check input typing
    # Missing duck-type check
    module TypeValidator
      def input_type_validator_meth(attr_name, type)
        define_method("valid_type_#{attr_name}?") do
          return true if @inputs[attr_name].is_a?(type)

          send("#{attr_name}?") &&
            send(
              :log_item_error_initialize,
              attr_name:, message: "Service argument with name #{attr_name} is not a #{type} but #{send(attr_name).class}"
            )
          false
        end
      end
    end
  end
end

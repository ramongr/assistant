# frozen_string_literal: true

module Assistant
  module Input
    # This module builds the required and required_if methods for every attribute
    module RequiredAttributes
      def input_require_validator_meth(attr_name, **options)
        define_method("valid_require_#{attr_name}?") do |log = true|
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
            attr_name:, message: "Service argument conditional requirement not met properly for #{attr_name}"
          )
          false
        end
      end
    end
  end
end

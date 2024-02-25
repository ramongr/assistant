# frozen_string_literal: true

require 'byebug'

module Assistant
  module Input
    # When verifying the default value we must make sure of two things:
    # The value of the default option matches the type (if there's a defined type)
    # The default value is only set if there are no values created for the attribute
    module DefaultValueBuilder
      def default_value_meth(attr_name, type:, **options)
        check_default_type(attr_name, type:, **options) if type.present?
        set_attribute(attr_name, options[:default])
      end

      def check_default_type(attr_name, type:, **options)
        define_method("valid_default_#{attr_name}?") do
          return true if options[:default].is_a?(type)

          send(
            :log_item_error_initialize,
            attr_name:, message: "#{attr_name} has a default value that doesn't match its type"
          )
          false
        end
      end
    end
  end
end

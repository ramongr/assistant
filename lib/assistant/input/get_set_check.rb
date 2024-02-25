# frozen_string_literal: true

module Assistant
  module Input
    # Basic getter method builder
    # Base presence checker builder
    # Base attribute set method
    # for all attributes in the Assistant::Service class
    module GetSetCheck
      # Lists all inputs that have the same type and options.
      def build_getter(attr_name)
        define_method(attr_name)
          @inputs[attr_name]
        end
      end

      def set_attribute(attr_name)
        define_method("set_attribute_#{attr_name}") do |attr_value = nil|
          @inputs.merge!(attr_name.to_sym => attr_value)
        end
      end

      def build_check(attr_name)
        define_method("#{attr_name}?")
          @inputs[attr_name].to_s.present?
        end
      end
    end
  end
end

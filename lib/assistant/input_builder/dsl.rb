# frozen_string_literal: true

# Public DSL surface: declarative `#input`/`#inputs` that register an
# input definition and generate the per-input accessor + validator
# instance methods on the host Service subclass. Calls into every
# other InputBuilder submodule.
module Assistant::InputBuilder::Dsl
  # Lists all inputs that have the same type and options.
  def inputs(attr_names, type:, **)
    attr_names.each do |attr_name|
      input(attr_name, type:, **)
    end
  end

  # Individual input with a specific type or options.
  def input(attr_name, type:, **options)
    process_default_option(attr_name, options[:default]) if options.key?(:default)
    options = process_optional_option(attr_name, options) if options.key?(:optional)
    register_input_definition(attr_name, type, options)

    # Base Methods
    input_getter_meth(attr_name)
    input_checker_meth(attr_name)

    # Input type validation method, simple and conditional requirement validation methods
    input_type_validator_meth(attr_name, type, **options)
    input_require_validator_meth(attr_name, **options) if options[:required] == true
    input_require_conditional_meth(attr_name, **options) if options[:required] == true && options[:if]
  end
end

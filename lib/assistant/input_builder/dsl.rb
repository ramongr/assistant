# frozen_string_literal: true

# Public DSL surface: declarative `#input`/`#inputs` that register an
# input definition and generate the per-input accessor + validator
# instance methods on the host Service subclass. Calls into every
# other InputBuilder submodule.
#
# These two methods deliberately keep their leading positional `name`
# parameter even though every other M12 helper is keyword-only --
# `input :foo, type: String` reads better as a class-body declaration
# than `input name: :foo, type: String`. The internal helpers we call
# below are still keyword-only; we just map the positional `attr_name`
# /`attr_names` here to `name:` / `names:` on the way down.
module Assistant::InputBuilder::Dsl
  # Lists all inputs that have the same type and options.
  def inputs(attr_names, type:, **)
    attr_names.each do |attr_name|
      input(attr_name, type:, **)
    end
  end

  # Individual input with a specific type or options.
  def input(attr_name, type:, **options)
    process_default_option(name: attr_name, default: options[:default]) if options.key?(:default)
    options = process_optional_option(name: attr_name, options:) if options.key?(:optional)
    register_input_definition(name: attr_name, type:, options:)

    # Base Methods
    input_getter_meth(name: attr_name)
    input_checker_meth(name: attr_name)

    # Input type validation method, simple and conditional requirement validation methods
    input_type_validator_meth(name: attr_name, type:, **options)
    input_require_validator_meth(name: attr_name, **options) if options[:required] == true
    input_require_conditional_meth(name: attr_name, **options) if options[:required] == true && options[:if]
  end
end

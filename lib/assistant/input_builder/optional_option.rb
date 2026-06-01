# frozen_string_literal: true

module Assistant
  module InputBuilder
    # M7: explicit `optional:` flag handling. Validates the value and
    # returns the canonical option hash (with `:required` derived from
    # `optional: false`). Mirrors `DefaultOption`'s shape so the `#input`
    # call site stays one line per option family.
    module OptionalOption
      def process_optional_option(attr_name, options)
        validate_optional!(attr_name, options)
        apply_optional_option(options)
      end

      # M7: `optional:` must be a boolean. `optional: true` together with
      # `required: true` is a contradiction. Both rules raise
      # `ArgumentError` at class-definition time, before any method is
      # generated.
      def validate_optional!(attr_name, options)
        optional = options[:optional]
        unless [true, false].include?(optional)
          raise ArgumentError, "optional: for input :#{attr_name} must be true or false, got #{optional.inspect}"
        end
        return unless optional == true && options[:required] == true

        raise ArgumentError, "input :#{attr_name} cannot be both required: true and optional: true"
      end

      # M7: pure translation of the validated `optional:` value into the
      # canonical `required:` flag used by downstream validator helpers.
      # `optional: false` -> `required: true`; `optional: true` is left
      # alone (no `valid_require_<name>?` is generated, matching the
      # default). The original `:optional` key is retained in
      # `input_definitions` for introspection. Non-mutating: callers
      # receive a new hash when a translation is applied.
      def apply_optional_option(options)
        options[:optional] == false ? options.merge(required: true) : options
      end
    end
  end
end

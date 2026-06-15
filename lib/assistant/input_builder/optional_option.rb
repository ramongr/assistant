# frozen_string_literal: true

# M7: explicit `optional:` flag handling. Validates the value and
# returns the canonical option hash (with `:required` derived from
# `optional: false`). Mirrors `DefaultOption`'s shape so the `#input`
# call site stays one line per option family.
module Assistant::InputBuilder::OptionalOption
  # Validate the `optional:` keyword for an input and return the
  # canonical option hash. `optional: false` is translated into
  # `required: true` so downstream validators see a single flag.
  #
  # @param name    [Symbol] input name
  # @param options [Hash]   options hash from the `#input` call
  # @return [Hash] the (possibly translated) options hash
  # @raise [ArgumentError] when `optional:` is non-boolean or contradicts `required: true`
  def process_optional_option(name:, options:)
    validate_optional!(name:, options:)
    apply_optional_option(options)
  end

  # M7: `optional:` must be a boolean. `optional: true` together with
  # `required: true` is a contradiction. Both rules raise
  # `ArgumentError` at class-definition time, before any method is
  # generated.
  def validate_optional!(name:, options:)
    optional = options[:optional]
    unless [true, false].include?(optional)
      raise ArgumentError, "optional: for input :#{name} must be true or false, got #{optional.inspect}"
    end
    return unless optional == true && options[:required] == true

    raise ArgumentError, "input :#{name} cannot be both required: true and optional: true"
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

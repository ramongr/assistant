# frozen_string_literal: true

# Generators for the per-input requirement validators. Canonical names
# (M9):
#
#   #valid_required_<name>?              # for `required: true`
#   #valid_required_conditional_<name>?  # for `required: true, if: ...`
#
# Pre-M9 names (`valid_require_*?`, `valid_require_conditional_*?`) are
# kept as deprecated aliases that delegate to the canonical method and
# emit a one-shot `Kernel.warn` per call site. They are scheduled for
# removal in `assistant 2.0`.
module Assistant::InputBuilder::RequireValidator
  # Guard so each deprecated alias warns at most once per textual call
  # site (file + lineno), regardless of how many times it is invoked or
  # how many input names are involved. Internal; tests reset it via
  # `.send(:__reset_deprecation_warnings__)`.
  DEPRECATION_WARNED = Set.new
  private_constant :DEPRECATION_WARNED

  def self.warn_deprecated(deprecated_name, canonical_name, caller_location)
    key = [canonical_name, caller_location.path, caller_location.lineno]
    return if DEPRECATION_WARNED.include?(key)

    DEPRECATION_WARNED << key
    Kernel.warn("assistant: `##{deprecated_name}` is deprecated; use `##{canonical_name}` (removed in assistant 2.0)")
  end

  # Test-only hook: clears the per-call-site dedupe set so a single
  # test process can exercise multiple "first warn" scenarios.
  def self.__reset_deprecation_warnings__
    DEPRECATION_WARNED.clear
  end

  def input_require_validator_meth(name:, **)
    canonical = :"valid_required_#{name}?"
    define_required_validator(canonical:, name:, **)
    define_deprecated_alias(:"valid_require_#{name}?", canonical)
  end

  def input_require_conditional_meth(name:, **)
    canonical = :"valid_required_conditional_#{name}?"
    define_required_conditional_validator(canonical:, name:, **)
    define_deprecated_alias(:"valid_require_conditional_#{name}?", canonical)
  end

  private

  def define_required_validator(canonical:, name:, **options)
    allow_nil = options.fetch(:allow_nil, false) == true

    define_method(canonical) do |log = true|
      # M2: explicit nil counts as "supplied" when allow_nil: true is set.
      return true if allow_nil && @inputs.key?(name)
      return true if options[:required] == true && send("#{name}?") == true

      log && send(
        :log_item_error_initialize, attr_name: name, message: "Service is missing argument with name #{name}"
      )
      false
    end
  end

  def define_required_conditional_validator(canonical:, name:, **options)
    define_method(canonical) do
      return false if send(:"valid_required_#{name}?", false) == false
      return true if options[:if].call(send(name))

      send(
        :log_item_error_initialize,
        attr_name: name,
        message: "Service argument conditional requirement not met properly for #{name}"
      )
      false
    end
  end

  def define_deprecated_alias(deprecated, canonical)
    define_method(deprecated) do |*args, **kwargs|
      ::Assistant::InputBuilder::RequireValidator.warn_deprecated(deprecated, canonical, caller_locations(1, 1).first)
      send(canonical, *args, **kwargs)
    end
  end
end

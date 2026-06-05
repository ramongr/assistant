# frozen_string_literal: true

# M1: class-time gate for the `default:` option — fail fast on illegal
# providers, warn on shared mutable literals. Pure side-effects, no
# interaction with the per-class definitions registry.
module Assistant::InputBuilder::DefaultOption
  def process_default_option(name:, default:)
    validate_default!(name:, default:)
    warn_on_mutable_default(name:, default:)
  end

  # M1: a default: provider must be either a literal value or a
  # zero-arity Proc/Lambda. Anything else that responds to #call (a
  # Method object, a custom callable) is rejected at class-definition
  # time.
  def validate_default!(name:, default:)
    if default.is_a?(Proc) && !default.arity.zero? && default.arity != -1
      raise ArgumentError, "default: for input :#{name} must be a zero-arity Proc, got arity #{default.arity}"
    elsif !default.is_a?(Proc) && default.respond_to?(:call)
      raise ArgumentError, "default: for input :#{name} must be a literal or a zero-arity Proc, not a #{default.class}"
    end
  end

  # M1: warn when a mutable literal default (unfrozen Array/Hash) is
  # used — such a default is shared across every instance of the
  # Service subclass and almost never what the author wants. Frozen
  # literals and Procs are safe and pass silently.
  def warn_on_mutable_default(name:, default:)
    return unless (default.is_a?(Array) || default.is_a?(Hash)) && !default.frozen?

    Kernel.warn("assistant: input :#{name} has a mutable #{default.class} default; " \
                'use `default: -> { ... }` to avoid sharing state across instances')
  end
end

# frozen_string_literal: true

require 'assistant'

module ComposingServicesExample
  # Inner service for `examples/composing_services/`. Validates that
  # `email` contains `@`, then always logs a `:email_normalized`
  # warning so the outer `SignUpUser` test can assert on the merged
  # timeline shape from `docs/examples/composing-services.md`.
  class CreateUser < Assistant::Service
    # Read-only value object returned from `#execute`. Mirrors the
    # `<User>` shape rendered in the docs snippet.
    User = Data.define(:id, :email, :name)

    input :email, type: String, required: true
    input :name, type: String, required: true

    def validate
      return if email.include?('@')

      log_item_error(source: :validate, detail: :email, message: 'must contain @')
    end

    def execute
      normalized = email.downcase
      log_item_warning(source: :create_user, detail: :email_normalized, message: "normalized to #{normalized}")

      User.new(id: 42, email: normalized, name:)
    end
  end
end

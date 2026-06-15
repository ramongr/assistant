# frozen_string_literal: true

require_relative 'create_user'
require_relative 'send_welcome_email'

module ComposingServicesExample
  # Outer service for `examples/composing_services/`. Calls
  # `CreateUser` and (on success) `SendWelcomeEmail` via
  # `#call_service`, which merges each inner timeline into this
  # service's `#logs`. Mirrors the docs snippet at
  # `docs/examples/composing-services.md` line for line.
  class SignUpUser < Assistant::Service
    input :email, type: String, required: true
    input :name, type: String, required: true

    def execute
      user = call_service(CreateUser, email:, name:)
      return if user.failure?

      call_service(SendWelcomeEmail, user_id: user.result.id)

      user.result
    end
  end
end

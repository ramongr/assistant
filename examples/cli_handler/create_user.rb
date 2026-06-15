# frozen_string_literal: true

require 'assistant'

module CliHandlerExample
  # Example `Assistant::Service` for `examples/cli_handler/`. Mirrors
  # the service shown verbatim in `docs/examples/cli-handler.md`:
  # validates the email contains `@`, emits a warning when `name` is
  # all-lowercase (so the CLI smoke test can exercise the
  # `:with_warnings` branch without needing extra inputs).
  class CreateUser < Assistant::Service
    input :email, type: String, required: true
    input :name, type: String, required: true

    def validate
      return if email.include?('@')

      log_item_error(source: :validate, detail: :email, message: 'must contain @')
    end

    def execute
      log_item_warning(source: :execute, detail: :name, message: 'name not capitalized') if name == name.downcase

      { id: 42, email:, name: }
    end
  end
end

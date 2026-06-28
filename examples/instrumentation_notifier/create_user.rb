# frozen_string_literal: true

require 'assistant'

# P11 of the GitHub Pages plan in docs/v1/index.md. Companion
# to docs/examples/instrumentation-notifier.md.
module InstrumentationNotifierExample
  # Minimal service whose runs are observed by `Assistant.notifier`.
  # Designed to exercise both terminal events:
  #
  # * Happy path (`email:` and `name:` valid) -> :service_started ->
  #   :service_validated -> :service_executed.
  # * Failure path (`email: nil`) -> :service_started ->
  #   :service_validated -> :service_failed, because the required-email
  #   validator logs an error before `#execute` is invoked.
  class CreateUser < Assistant::Service
    input :email, type: String, required: true
    input :name, type: String, required: true

    def execute
      add_log(level: :error, source: :validate, detail: :email, message: 'must contain @') unless email.include?('@')
      { id: 42, email:, name: } if errors.empty?
    end
  end
end

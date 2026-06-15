# frozen_string_literal: true

require 'assistant'

module SidekiqWorkerExample
  # Example `Assistant::Service` for `examples/sidekiq_worker/`. Same
  # shape as the other example services: validates `email` contains
  # `@`, demotes to `:with_warnings` when `name` is all-lowercase, so
  # the worker test can exercise each branch.
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

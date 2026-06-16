# frozen_string_literal: true

require 'assistant'

module RbsGeneratorExample
  # Service used by `examples/rbs_generator/` to demonstrate the
  # `assistant-rbs` per-class signature generator.
  class CreateUser < Assistant::Service
    input :email, type: String, required: true
    input :name, type: String, required: true
    input :role, type: [String, Symbol], allow_nil: true, default: nil

    def validate
      return if email.include?('@')

      log_item_error(source: :validate, detail: :email, message: 'must contain @')
    end

    def execute
      { email:, name:, role: role || :member }
    end
  end
end

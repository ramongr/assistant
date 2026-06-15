# frozen_string_literal: true

require 'assistant'

module RailsServiceExample
  # Example `Assistant::Service` for `examples/rails_service/`. Mirrors
  # the `CreateUser` service shown verbatim in
  # `docs/examples/rails-service.md`: validates email + name, demotes to
  # `:with_warnings` when `age` is missing, fails with `:with_errors`
  # when the email is missing the `@` sigil. The returned hash is
  # intentionally plain-Ruby so the sibling `UsersController` POJO can
  # `render json: result` without any Rails serializer in the loop.
  class CreateUser < Assistant::Service
    input :email, type: String, required: true
    input :name, type: String, required: true
    input :age, type: Integer, allow_nil: true, default: nil

    def validate
      return if email.include?('@')

      log_item_error(source: :validate, detail: :email, message: 'must contain @')
    end

    def execute
      log_item_warning(source: :execute, detail: :age, message: 'age missing') if age.nil?

      { id: 42, email:, name:, age: }
    end
  end
end

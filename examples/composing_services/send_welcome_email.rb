# frozen_string_literal: true

require 'assistant'

module ComposingServicesExample
  # Inner service for `examples/composing_services/`. Always logs a
  # `:throttled` warning so the outer `SignUpUser` test can assert
  # that the inner timeline merges into the outer one in declaration
  # order (after `CreateUser`'s `:email_normalized` warning).
  class SendWelcomeEmail < Assistant::Service
    input :user_id, type: Integer, required: true

    def execute
      log_item_warning(source: :send_welcome_email, detail: :throttled, message: 'welcome queued for 1s delay')

      { user_id:, queued: true }
    end
  end
end

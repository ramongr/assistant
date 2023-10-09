# frozen_string_literal: true

FactoryBot.define do
  factory :log_item_info, class: 'Assistant::LogItem' do
    detail { Faker::Lorem.sentence }
    level { :info }
    message { 'message' }
    source { :source }
    trace { nil }

    initialize_with { new(**attributes) }

    factory :log_item_warning, class: 'Assistant::LogItem' do
      level { :warning }
    end

    factory :log_item_error, class: 'Assistant::LogItem' do
      level { :error }
    end
  end

  factory :invalid_log_item, class: 'Assistant::LogItem' do
    detail { '' }
    level { '' }
    source { '' }
    message { '' }

    initialize_with { new(**attributes) }
  end
end

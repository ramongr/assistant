# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

require 'assistant'
require 'minitest/autorun'
require 'minitest/pride'
require 'stringio'

module TestHelpers
  module LogItems
    def build_log_item(level: :info, source: :source, detail: 'detail', message: 'message', trace: nil)
      Assistant::LogItem.new(level:, source:, detail:, message:, trace:)
    end

    def build_log_items(count, **)
      Array.new(count) { build_log_item(**) }
    end
  end
end

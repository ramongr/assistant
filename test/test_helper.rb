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

  # Captures everything written to $stderr inside the given block and
  # returns it as a String. Used by InputBuilder tests that assert on
  # `Kernel.warn` output (M1 mutable-default warning, etc.).
  module IoCapture
    def capture_io_warn
      original = $stderr
      $stderr = StringIO.new
      yield
      $stderr.string
    ensure
      $stderr = original
    end
  end
end

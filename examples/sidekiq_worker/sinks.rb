# frozen_string_literal: true

module SidekiqWorkerExample
  # Sink for `:with_warnings` runs. In a real app this would wrap an
  # APM client or message bus; for the example it is a tiny singleton
  # with a class-level array so the regression test can assert on the
  # calls without stubs.
  module WarningsSink
    @published = []

    class << self
      attr_reader :published

      def publish(worker:, items:)
        @published << { worker:, items: }
      end

      def clear
        @published.clear
      end
    end
  end

  # Sink for `:with_errors` runs. Same shape as `WarningsSink`; kept
  # separate so the test can assert errors land here and warnings do
  # not (and vice versa).
  module ErrorsSink
    @published = []

    class << self
      attr_reader :published

      def publish(worker:, items:)
        @published << { worker:, items: }
      end

      def clear
        @published.clear
      end
    end
  end
end

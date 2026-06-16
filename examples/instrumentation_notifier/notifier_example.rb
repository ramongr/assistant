# frozen_string_literal: true

require_relative 'create_user'

# Two-level nesting (rather than the cop-preferred compact form) is
# deliberate: it keeps `CreateUser` resolving via `Module.nesting` to
# the sibling `InstrumentationNotifierExample::CreateUser` and out of
# reach of any top-level `CreateUser` constant other example folders
# (e.g. `examples/sidekiq_worker/create_user_worker.rb`) install when
# they get loaded earlier in the same process.
# rubocop:disable Style/CompactModuleNesting
module InstrumentationNotifierExample
  # Module-level driver invoked by the integration test and by the
  # README's manual-run incantation. Returns the captured event tuples
  # from both the happy and failure paths so callers can inspect them
  # without globally configuring a notifier. Demonstrates the
  # `Assistant.notifier=` contract documented at
  # docs/examples/instrumentation-notifier.md.
  module NotifierExample
    # Run `CreateUser` once on the happy path and once on the failure
    # path with a stub notifier installed. Returns
    # `{ ok: Array, failed: Array }` where each value is a list of
    # `[event_symbol, payload_hash]` tuples in dispatch order.
    #
    # The notifier is reset to the gem default in an `ensure` so the
    # process-wide configuration is never left dirty.
    def self.run
      events = []
      Assistant.notifier = ->(event, payload) { events << [event, payload] }

      CreateUser.run(email: 'a@b.com', name: 'Alice')
      ok = events.dup

      events.clear
      CreateUser.run(email: nil, name: 'Alice')
      failed = events.dup

      { ok: ok, failed: failed }
    ensure
      Assistant.notifier = nil
    end
  end
end
# rubocop:enable Style/CompactModuleNesting

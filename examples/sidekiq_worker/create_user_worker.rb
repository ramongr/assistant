# frozen_string_literal: true

# `examples/sidekiq_worker/` runnable worker. Mirrors the snippet in
# `docs/examples/sidekiq-worker.md` line-for-line, including the
# unqualified `CreateUser` / `WarningsSink` / `ErrorsSink` references
# in the worker body.
#
# - `Sidekiq::Worker` comes from the in-folder `fake_sidekiq.rb` stub
#   so the example runs without depending on the real `sidekiq` gem.
# - `CreateUser`, `WarningsSink`, `ErrorsSink` are top-level aliases of
#   the namespaced `SidekiqWorkerExample::*` constants. Loading this
#   file from a sibling test therefore lets the worker body match the
#   docs snippet while keeping the canonical defs in the example
#   namespace for assertion + reset.

require_relative 'create_user'
require_relative 'fake_sidekiq'
require_relative 'sinks'

CreateUser = SidekiqWorkerExample::CreateUser unless defined?(CreateUser)
WarningsSink = SidekiqWorkerExample::WarningsSink unless defined?(WarningsSink)
ErrorsSink = SidekiqWorkerExample::ErrorsSink unless defined?(ErrorsSink)

# Example Sidekiq worker that runs `CreateUser` idempotently and
# routes warnings + errors to separate sinks instead of re-raising.
class CreateUserWorker
  include Sidekiq::Worker

  sidekiq_options retry: 5, queue: :default

  def perform(user_attrs)
    case CreateUser.run(**user_attrs.transform_keys(&:to_sym))
    in { result:, status: :ok }
      # Done. Sidekiq sees no exception, no retry.
    in { result:, status: :with_warnings, warnings: }
      WarningsSink.publish(worker: self.class.name, items: warnings.map(&:item))
    in { errors:, status: :with_errors }
      # Permanent business-rule failure: don't retry, surface to ops.
      ErrorsSink.publish(worker: self.class.name, items: errors.map(&:item))
    end
  end
end

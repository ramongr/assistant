# frozen_string_literal: true

# Stub of the tiny slice of the Sidekiq API the worker example needs:
# `Sidekiq::Worker` as a no-op include and a `sidekiq_options` DSL that
# stores its argument on the class. Lets `examples/sidekiq_worker/`
# stay runnable without the real `sidekiq` gem as a dependency.
#
# The compact-nesting cop is disabled because we are deliberately
# providing the public `Sidekiq::Worker` constant path, not a private
# helper.

# rubocop:disable Style/CompactModuleNesting
module Sidekiq
  # No-op include for the example worker. The real `Sidekiq::Worker`
  # registers job classes with the server-side dispatcher; here it just
  # exposes the `sidekiq_options` class-method DSL.
  module Worker
    def self.included(base)
      base.extend(ClassMethods)
    end

    # Mirrors `Sidekiq::Worker::ClassMethods#sidekiq_options` enough to
    # let the example declare retry + queue settings and let the test
    # assert that the call happened.
    module ClassMethods
      def sidekiq_options(opts = {})
        @sidekiq_options ||= {}
        @sidekiq_options.merge!(opts)
      end

      def sidekiq_options_hash
        @sidekiq_options || {}
      end
    end
  end
end
# rubocop:enable Style/CompactModuleNesting

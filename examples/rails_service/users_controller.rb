# frozen_string_literal: true

require_relative 'create_user'

module RailsServiceExample
  # Plain-Ruby controller that mirrors the Rails-shaped controller in
  # `docs/examples/rails-service.md`. The example deliberately avoids a
  # Rails runtime dependency: `UsersController` is a POJO that exposes
  # `#create`, takes `params:` + `logger:` via its initializer, and
  # returns a `{ status:, body: }` hash so a test can assert on the
  # response shape without booting `ActionController`.
  class UsersController
    # @param params [Hash{Symbol => Hash}] shaped like Rails's `params`
    #   (`{ user: { email:, name:, age: } }`).
    # @param logger [#warn] anything responding to `#warn(Array)`.
    def initialize(params:, logger: NullLogger.new)
      @params = params
      @logger = logger
    end

    def create
      case CreateUser.run(**user_params)
      in { result: user, status: :ok }
        { status: :created, body: user }
      in { result: user, status: :with_warnings, warnings: }
        @logger.warn(warnings.map(&:item))
        { status: :created, body: user }
      in { errors:, status: :with_errors }
        { status: :unprocessable_entity, body: { errors: errors.map(&:item) } }
      end
    end

    private

    def user_params
      @params.fetch(:user)
    end

    # Tiny stand-in for `Rails.logger` so the example runs without any
    # framework. The test injects a recording double instead.
    class NullLogger
      def warn(_items); end
    end
  end
end

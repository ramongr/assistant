# Rails service

A Rails-shaped controller that calls a service and pattern-matches on
the result hash:

```ruby
class UsersController < ApplicationController
  def create
    case CreateUser.run(**user_params.to_h.symbolize_keys)
    in { result: user, status: :ok }
      render json: user, status: :created
    in { result: user, status: :with_warnings, warnings: }
      Rails.logger.warn(warnings.map(&:item))
      render json: user, status: :created
    in { errors:, status: :with_errors }
      render json: { errors: errors.map(&:item) },
             status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:email, :name)
  end
end
```

Notes:

* `Service.run` never raises for application-level failures — it always
  returns a hash. Use `rescue` only for true exceptions (network,
  database, etc.), and let `:with_errors` carry the validation /
  business-rule failures.
* `LogItem#item` returns a `Hash{Symbol => Object}` that's safe to
  pass straight to `render json:`.

See the [Getting started guide](../getting-started.md) for the
result-shape contract and the
[API reference](../api-reference.md#result-shape) for the full status
enum.

> Source: [`examples/rails_service/`](https://github.com/ramongr/assistant/tree/main/examples/rails_service) ·
> Test: [`test/examples/rails_service_example_test.rb`](https://github.com/ramongr/assistant/blob/main/test/examples/rails_service_example_test.rb)

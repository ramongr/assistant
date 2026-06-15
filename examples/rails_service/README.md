# Rails service

How to call an `Assistant::Service` from a Rails-shaped controller and
pattern-match on the result hash without booting Rails. The matching
site page is
[`docs/examples/rails-service.md`](../../docs/examples/rails-service.md);
this directory is the runnable mirror referenced from that page.

## Files

| File | Role |
| --- | --- |
| [`create_user.rb`](./create_user.rb) | The service: declares `email` / `name` / `age` inputs, validates the email, demotes to `:with_warnings` when `age` is missing, fails with `:with_errors` when the email is missing the `@` sigil. |
| [`users_controller.rb`](./users_controller.rb) | Plain-Ruby `UsersController` that takes `params:` + `logger:` via its initializer and returns a `{ status:, body: }` response hash. Mirrors the case-match in the docs page. |

## Why a POJO controller?

The docs page shows a real `ApplicationController` subclass for context,
but pulling in Rails just to exercise three `case … in …` branches would
make the example painful to read and slow to test. The POJO version
preserves the contract that matters — the `Service.run` payload's
shape — without dragging in `actionpack`.

The regression test
[`test/examples/rails_service_example_test.rb`](../../test/examples/rails_service_example_test.rb)
loads these two files and asserts on the `:ok`, `:with_warnings`, and
`:with_errors` branches.

## Running it manually

```ruby
$ bundle exec ruby -Ilib -rexamples/rails_service/users_controller -e '
  controller = RailsServiceExample::UsersController.new(
    params: { user: { email: "a@b.com", name: "Alice", age: 30 } }
  )
  pp controller.create
'
# => {status: :created, body: {id: 42, email: "a@b.com", name: "Alice", age: 30}}
```

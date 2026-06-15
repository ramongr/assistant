# Composing services

How to nest one `Assistant::Service` inside another using
`#call_service`, and verify the inner timeline merges into the outer
one in declaration order. The matching site page is
[`docs/examples/composing-services.md`](../../docs/examples/composing-services.md);
this directory is the runnable mirror referenced from that page.

## Files

| File | Role |
| --- | --- |
| [`create_user.rb`](./create_user.rb) | First inner service. Validates `email`, then warns `:email_normalized` and returns a `User` data struct with `.id`. |
| [`send_welcome_email.rb`](./send_welcome_email.rb) | Second inner service. Takes `user_id`, warns `:throttled`, returns a queued-acknowledgement hash. |
| [`sign_up_user.rb`](./sign_up_user.rb) | Outer service. Calls `CreateUser` then (on success) `SendWelcomeEmail` via `#call_service`, byte-identical to the docs snippet. |

## What the test pins

The merged-timeline shape from
[`docs/examples/composing-services.md`](../../docs/examples/composing-services.md)
is the documented contract for `#call_service`. The regression test
[`test/examples/composing_services_example_test.rb`](../../test/examples/composing_services_example_test.rb)
asserts:

- Happy path returns `status: :with_warnings` and exactly two
  warnings, in the order `:email_normalized` (from `CreateUser`)
  then `:throttled` (from `SendWelcomeEmail`).
- The outer `#result` is the `User` returned by `CreateUser`, not the
  hash returned by `SendWelcomeEmail` (the example keeps `user.result`
  as the trailing expression).
- When `CreateUser` fails (invalid email), `SignUpUser` short-circuits
  before `SendWelcomeEmail` runs, the outer status is `:with_errors`,
  and the inner `:email` error is on the outer timeline (because
  `merge_logs` ran before the early return).

## Running it manually

```ruby
$ bundle exec ruby -Ilib -rexamples/composing_services/sign_up_user -e '
  pp ComposingServicesExample::SignUpUser.run(email: "a@b.com", name: "Alice")
  pp ComposingServicesExample::SignUpUser.run(email: "oops",    name: "Alice")
'
```

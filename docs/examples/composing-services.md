# Composing services

`#call_service` runs a sibling service from inside `#execute` and
merges its log timeline into the outer service automatically — see the
[Composing services guide](../guides/composing-services.md) for the
full contract.

A two-step signup, where `CreateUser` looks up or creates the user
and `SendWelcomeEmail` queues the welcome:

```ruby
class SignUpUser < Assistant::Service
  input :email, type: String, required: true
  input :name,  type: String, required: true

  def execute
    user = call_service(CreateUser, email:, name:)
    return if user.failure?

    call_service(SendWelcomeEmail, user_id: user.result.id)

    user.result
  end
end
```

What the merged timeline looks like:

```text
SignUpUser.run(email: 'a@b.com', name: 'Alice')
# => { result: <User>, status: :with_warnings,
#      warnings: [
#        #<LogItem :email_normalized 'normalized to a@b.com'>,  # from CreateUser
#        #<LogItem :throttled 'welcome queued for 1s delay'>    # from SendWelcomeEmail
#      ] }
```

Notes:

* If `CreateUser` returns `:with_errors`, `user.failure?` is true and
  the early-return propagates: the outer status downgrades to
  `:with_errors` automatically because the inner errors were merged
  via `merge_logs`.
* Use `call_service` (not `CreateUser.run(...)`) so the inner service's
  logs join the outer timeline. Calling `.run` directly silently
  discards them.

> Source: [`examples/composing_services/`](https://github.com/ramongr/assistant/tree/main/examples/composing_services) ·
> Test: [`test/examples/composing_services_example_test.rb`](https://github.com/ramongr/assistant/blob/main/test/examples/composing_services_example_test.rb)

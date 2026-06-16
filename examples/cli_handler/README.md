# CLI handler

How to drive an `Assistant::Service` from an `OptionParser`-based
command-line script and turn the result hash's `:status` into a
meaningful process exit code. The matching site page is
[`docs/examples/cli-handler.md`](../../docs/examples/cli-handler.md);
this directory is the runnable mirror referenced from that page.

Start with the [getting started guide](../../docs/getting-started.md) if this
is your first Assistant service. Rendered docs:
<https://ramongr.github.io/assistant/#/examples/cli-handler>.

## Files

| File | Role |
| --- | --- |
| [`create_user.rb`](./create_user.rb) | The service: `email` + `name` inputs, fails with `:with_errors` when the email is missing `@`, demotes to `:with_warnings` when the name is all-lowercase (so the smoke test can exercise the warning branch without a third input). |
| [`create_user_cli.rb`](./create_user_cli.rb) | Executable script (`chmod +x`) with the `OptionParser` setup and the three-way case-match on the result. Exits 0 for `:ok` / `:with_warnings`, exits 1 for `:with_errors`. |

## Running it manually

```sh
$ bundle exec ruby examples/cli_handler/create_user_cli.rb --email a@b.com --name Alice
ok: {id: 42, email: "a@b.com", name: "Alice"}

$ bundle exec ruby examples/cli_handler/create_user_cli.rb --email a@b.com --name alice
ok (with warnings): {id: 42, email: "a@b.com", name: "alice"}
  warning: name not capitalized

$ bundle exec ruby examples/cli_handler/create_user_cli.rb --email oops --name Alice
error: must contain @
$ echo $?
1
```

The regression test
[`test/examples/cli_handler_example_test.rb`](../../test/examples/cli_handler_example_test.rb)
shells out to the script with `Open3.capture3` and asserts on the exit
code + `$stderr` text for each branch.

## Why a top-level `CreateUser` alias?

The runnable script defines `CreateUser = CliHandlerExample::CreateUser`
so its body reads line-for-line like the snippet in the docs page.
Loading the service file in a test (which `require`s
`examples/cli_handler/create_user`) only sees the namespaced class, so
the alias does not leak between sibling tests.

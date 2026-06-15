# CLI handler
{: .no_toc }

An `OptionParser`-driven script that runs a service and derives the
process exit code from `#status`:

```ruby
#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'
require 'assistant'
require_relative 'create_user'

options = {}
OptionParser.new do |opts|
  opts.banner = 'Usage: create_user --email EMAIL --name NAME'
  opts.on('-eEMAIL', '--email=EMAIL') { |v| options[:email] = v }
  opts.on('-nNAME',  '--name=NAME')   { |v| options[:name]  = v }
end.parse!

case CreateUser.run(**options)
in { result:, status: :ok }
  warn "ok: #{result.inspect}"
  exit 0
in { result:, status: :with_warnings, warnings: }
  warn "ok (with warnings): #{result.inspect}"
  warnings.each { |w| warn "  warning: #{w.message}" }
  exit 0
in { errors:, status: :with_errors }
  errors.each { |e| warn "error: #{e.message}" }
  exit 1
end
```

Notes:

* `:ok` and `:with_warnings` both exit 0 — warnings are still a
  successful run. Only `:with_errors` exits 1.
* Print to `$stderr` (`warn`) so the script can be piped without log
  noise leaking into stdout.

{: .note }
> A runnable `examples/cli_handler/` script + smoke test ships in
> [P7](https://github.com/ramongr/assistant/blob/main/docs/v1/08-github-pages.md#p6p12-examples-one-pr-per-example)
> of the GitHub Pages plan.

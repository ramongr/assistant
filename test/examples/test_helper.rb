# frozen_string_literal: true

# Shared scaffolding for the `test/examples/<slug>_example_test.rb`
# suites that exercise the runnable scripts under `examples/<slug>/`
# (P6-P12 of docs/v1/08-github-pages.md).
#
# Conventions:
#
# 1. Each test `require_relative`s this file, which pulls in the
#    project-wide `test/test_helper.rb` (SimpleCov, Minitest, the
#    `TestHelpers::*` mixins).
# 2. Example scripts under `examples/<slug>/` define their public
#    surface inside an `Examples::<Slug>` module so loading one script
#    does not pollute the global constant namespace across sibling
#    tests.
# 3. Tests resolve script paths via `ExampleTestHelpers::EXAMPLES_ROOT`
#    rather than hard-coding `File.expand_path` per file.

require_relative '../test_helper'

module ExampleTestHelpers
  # Absolute path to the repo-root `examples/` directory. Use it so
  # tests stay decoupled from the test file's own location:
  #
  #   require File.join(ExampleTestHelpers::EXAMPLES_ROOT, 'rails_service/create_user')
  EXAMPLES_ROOT = File.expand_path('../../examples', __dir__)
end

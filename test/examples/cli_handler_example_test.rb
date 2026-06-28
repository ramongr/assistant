# frozen_string_literal: true

require_relative 'test_helper'
require 'open3'

# Regression test for `examples/cli_handler/` (P7 of
# docs/v1/index.md). Shells out to
# `examples/cli_handler/create_user_cli.rb` and asserts on the exit
# code + stderr text for each `case … in …` branch promised by
# `docs/examples/cli-handler.md`.
class CliHandlerExampleTest < Minitest::Test
  CLI_SCRIPT = File.join(ExampleTestHelpers::EXAMPLES_ROOT, 'cli_handler', 'create_user_cli.rb')

  def test_happy_path_exits_zero_and_writes_ok_line
    stdout, stderr, status = run_cli('--email', 'a@b.com', '--name', 'Alice')

    assert_predicate status, :success?
    assert_equal 0, status.exitstatus
    assert_empty stdout
    assert_match(/\Aok: \{.*id.*42.*\}/, stderr.lines.first)
  end

  def test_with_warnings_exits_zero_and_lists_warnings_on_stderr
    stdout, stderr, status = run_cli('--email', 'a@b.com', '--name', 'alice')

    assert_predicate status, :success?
    assert_equal 0, status.exitstatus
    assert_empty stdout
    assert_match(/\Aok \(with warnings\):/, stderr.lines.first)
    assert_includes stderr, '  warning: name not capitalized'
  end

  def test_with_errors_exits_nonzero_and_lists_errors_on_stderr
    stdout, stderr, status = run_cli('--email', 'oops', '--name', 'Alice')

    refute_predicate status, :success?
    assert_equal 1, status.exitstatus
    assert_empty stdout
    assert_includes stderr, 'error: must contain @'
  end

  private

  # Runs the CLI in a child Ruby with the gem's `lib/` on `$LOAD_PATH`
  # so `require 'assistant'` resolves without an installed gem.
  def run_cli(*)
    Open3.capture3(RbConfig.ruby, '-I', File.expand_path('../../lib', __dir__), CLI_SCRIPT, *)
  end
end

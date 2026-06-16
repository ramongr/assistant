# frozen_string_literal: true

require_relative 'test_helper'
require 'open3'
require 'tmpdir'

require File.join(ExampleTestHelpers::EXAMPLES_ROOT, 'rbs_generator/create_user')

# Regression test for `examples/rbs_generator/` (P12 of
# docs/v1/08-github-pages.md). Pins both the service behavior and the
# generated signature committed beside the example.
class RbsGeneratorExampleTest < Minitest::Test
  SERVICE_FILE = File.join(ExampleTestHelpers::EXAMPLES_ROOT, 'rbs_generator', 'create_user.rb')
  EXPECTED_SIG = File.join(
    ExampleTestHelpers::EXAMPLES_ROOT,
    'rbs_generator',
    'sig',
    'rbs_generator_example',
    'create_user.rbs'
  )
  ASSISTANT_RBS = File.expand_path('../../exe/assistant-rbs', __dir__)
  LIB_DIR = File.expand_path('../../lib', __dir__)

  def test_service_runs_with_generated_input_readers
    payload = RbsGeneratorExample::CreateUser.run(email: 'ada@example.com', name: 'Ada', role: :admin)

    assert_equal :ok, payload.fetch(:status)
    assert_equal({ email: 'ada@example.com', name: 'Ada', role: :admin }, payload.fetch(:result))
  end

  def test_service_soft_fails_on_invalid_email
    payload = RbsGeneratorExample::CreateUser.run(email: 'oops', name: 'Ada')

    assert_equal :with_errors, payload.fetch(:status)
    assert_nil payload.fetch(:result)
    assert_equal 'must contain @', payload.fetch(:errors).first.message
  end

  def test_generator_output_matches_committed_signature
    Dir.mktmpdir do |dir|
      stdout, stderr, status = Open3.capture3(
        RbConfig.ruby,
        '-I',
        LIB_DIR,
        ASSISTANT_RBS,
        SERVICE_FILE,
        '--output',
        dir,
        '--quiet'
      )

      assert_predicate status, :success?, stderr
      assert_empty stdout
      assert_empty stderr

      generated = File.join(dir, 'rbs_generator_example', 'create_user.rbs')

      assert_equal File.read(EXPECTED_SIG), File.read(generated)
    end
  end
end

# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rake/testtask'

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/**/*_test.rb']
  t.warning = false
end

begin
  require 'rubocop/rake_task'
  RuboCop::RakeTask.new
rescue LoadError
  # rubocop is a development-only dependency; the rubocop task is unavailable
  # in environments (e.g. release builds) where it isn't installed.
end

desc 'Run Steep type-check (matches the required CI job)'
task :steep do
  sh 'bundle exec steep check --jobs=1'
end

desc 'YARD: build docs into doc/ and enforce 100% public-method coverage'
task :yard do
  sh 'bundle exec yard doc --quiet'
  stats = `bundle exec yard stats --list-undoc 2>&1`
  match = stats.match(/([\d.]+)% documented/)
  abort "yard: could not parse stats output:\n#{stats}" unless match

  percentage = match[1].to_f
  abort "yard: only #{format('%.2f', percentage)}% documented; full output:\n#{stats}" if percentage < 100.0
  puts "yard: #{format('%.2f', percentage)}% documented"
end

desc 'Run the full local CI pipeline: test + rubocop + steep + yard'
task ci: %i[test rubocop steep yard]

namespace :docs do
  desc 'Serve the Docsify site on http://127.0.0.1:4000 (Ctrl-C to stop)'
  task :serve do
    # Docsify is a client-side SPA: no build step, no toolchain. We
    # just serve `docs/` over WEBrick (shipped with stdlib via the
    # `un` command). The Pages workflow uploads the same directory as
    # the Pages artifact verbatim.
    sh 'ruby -run -e httpd docs -p 4000'
  end
end

task default: :test

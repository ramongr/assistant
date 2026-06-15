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
  desc 'Install the mkdocs toolchain pinned in requirements-docs.txt'
  task :install do
    sh 'python3 -m pip install --user -r requirements-docs.txt'
  end

  desc 'Build the mkdocs site into ./site (mirrors the CI Pages build)'
  task :build do
    sh 'python3 -m mkdocs build --strict'
  end

  desc 'Serve the mkdocs site on http://127.0.0.1:8000 with live reload'
  task :serve do
    sh 'python3 -m mkdocs serve'
  end
end

task default: :test

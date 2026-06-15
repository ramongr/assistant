# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rake/testtask'
require 'webrick' # stdlib gem (pinned in Gemfile); used by `rake docs:serve`.

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
  desc 'Serve the Docsify site on http://127.0.0.1:4000/assistant/ (Ctrl-C to stop)'
  task :serve do
    # Docsify runs in hash-mode routing, so every navigable URL resolves to
    # `docs/index.html` (no SPA-fallback servlet required). We mount `docs/`
    # at `/assistant/` over WEBrick so local URLs match the production base
    # path verbatim.
    root  = File.expand_path('docs', __dir__)
    mount = '/assistant'

    server = WEBrick::HTTPServer.new(Port: 4000, BindAddress: '127.0.0.1')
    server.mount(mount, WEBrick::HTTPServlet::FileHandler, root, FancyIndexing: false)
    server.mount_proc('/') do |_req, res|
      res.set_redirect(WEBrick::HTTPStatus::Found, "#{mount}/")
    end

    trap('INT') { server.shutdown }
    puts "Serving http://127.0.0.1:4000#{mount}/ (Ctrl-C to stop)"
    server.start
  end
end

task default: :test

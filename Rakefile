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

# WEBrick servlet for `rake docs:serve`. Mirrors GitHub Pages' SPA
# fallback: when the requested file doesn't exist (history-mode routing
# hits a non-file path), serve `docs/404.html` (a verbatim copy of
# `docs/index.html`) with HTTP 404 so Docsify can pick up the route on
# the client. Defined at the top level so RuboCop's
# `Rake/MethodDefinitionInTask` cop stays happy.
class DocsSpaServlet < WEBrick::HTTPServlet::FileHandler
  # rubocop:disable Naming/MethodName -- WEBrick API requires `do_GET`.
  def do_GET(req, res)
    super
  rescue WEBrick::HTTPStatus::NotFound
    res.status = 404
    res.content_type = 'text/html'
    res.body = File.read(File.join(@root, '404.html'))
  end
  # rubocop:enable Naming/MethodName
end

namespace :docs do
  desc 'Serve the Docsify site on http://127.0.0.1:4000/assistant/ (Ctrl-C to stop)'
  task :serve do
    # Docsify runs in history-mode routing (`routerMode: 'history'`), so
    # unknown URLs like `/assistant/guides/inputs` must serve the SPA
    # shell instead of 404ing. We mount `docs/` at `/assistant/` (matching
    # the GitHub Pages base path) and fall back to `docs/404.html` via
    # `DocsSpaServlet`.
    root  = File.expand_path('docs', __dir__)
    mount = '/assistant'

    server = WEBrick::HTTPServer.new(Port: 4000, BindAddress: '127.0.0.1')
    server.mount(mount, DocsSpaServlet, root, FancyIndexing: false)
    server.mount_proc('/') do |_req, res|
      res.set_redirect(WEBrick::HTTPStatus::Found, "#{mount}/")
    end

    trap('INT') { server.shutdown }
    puts "Serving http://127.0.0.1:4000#{mount}/ (Ctrl-C to stop)"
    server.start
  end
end

task default: :test

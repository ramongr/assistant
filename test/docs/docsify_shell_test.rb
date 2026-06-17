# frozen_string_literal: true

require 'test_helper'

class DocsifyShellTest < Minitest::Test
  ROOT = File.expand_path('../..', __dir__)
  SIDEBAR = File.join(ROOT, 'docs/_sidebar.md')
  SHELLS = [File.join(ROOT, 'docs/index.html'), File.join(ROOT, 'docs/404.html')].freeze

  def test_sidebar_uses_docsify_routes_for_active_subnav_matching
    sidebar = File.read(SIDEBAR)

    refute_match(%r{/assistant/#/}, sidebar)
    refute_match(%r{\]\(#/}, sidebar)
    refute_match(%r{\[Overview\]\(/examples/README\.md\)}, sidebar)
    assert_match(%r{\[Home\]\(/\)}, sidebar)
    assert_match(%r{\[Getting started\]\(/getting-started\.md\)}, sidebar)
  end

  def test_docsify_shells_pin_sidebar_and_wordmark_routes
    SHELLS.each do |shell|
      html = File.read(shell)

      assert_includes html, "nameLink: '#/'", shell
      assert_includes html, "basePath: '/assistant/'", shell
      assert_includes html, "'/.*/_sidebar.md': '/_sidebar.md'", shell
    end
  end

  def test_docsify_shells_style_sidebar_toggle_states
    SHELLS.each do |shell|
      html = File.read(shell)

      assert_includes html, '<body class="assistant-sidebar-shell">', shell
      assert_includes html, 'body.assistant-sidebar-shell .sidebar {', shell
      assert_includes html, 'bottom: auto;', shell
      assert_includes html, 'top: 0.875rem;', shell
      assert_includes html, 'content: "\\00d7";', shell
      assert_includes html, 'body.assistant-sidebar-shell.close .sidebar-toggle::before', shell
      assert_includes html, 'content: "\\2630";', shell
    end
  end
end

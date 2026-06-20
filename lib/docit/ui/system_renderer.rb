# frozen_string_literal: true

module Docit
  module UI
    class SystemRenderer < BaseRenderer
      def render
        <<~HTML
          <!DOCTYPE html>
          <html lang="en">
          <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>#{title} – System Architecture</title>
            <script>
              /* Apply the saved theme before first paint to avoid a flash.
                 Default is light; only switch to dark when explicitly chosen. */
              (function() {
                try {
                  var saved = localStorage.getItem("docit-theme");
                  if (saved === "dark") document.documentElement.setAttribute("data-theme", "dark");
                } catch (e) {}
              })();
            </script>
            <style>#{SystemStyles.css}</style>
          </head>
          <body>
            #{nav_bar(active: :system)}
            <div class="system-shell">
              <header class="system-toolbar">
                <div class="toolbar-group toolbar-brand">
                  <div class="brand-mark" aria-hidden="true">
                    <svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round">
                      <rect x="2" y="2" width="5" height="5" rx="1.2"/><rect x="9" y="2" width="5" height="5" rx="1.2"/>
                      <rect x="2" y="9" width="5" height="5" rx="1.2"/><rect x="9" y="9" width="5" height="5" rx="1.2"/>
                      <path d="M7 4.5h2M4.5 7v2M11.5 7v2"/>
                    </svg>
                  </div>
                  <div class="toolbar-title">
                    <strong>System Architecture</strong>
                    <span>Interactive diagram · drag, zoom, explore</span>
                  </div>
                </div>
                <div class="toolbar-group toolbar-filters" id="diagram-filters">
                  <input id="search" class="control" type="search" placeholder="Search nodes…" autocomplete="off">
                  <select id="diagram-section-filter" class="control"><option value="">All sections</option></select>
                </div>
                <div class="toolbar-group toolbar-filters" id="docs-filters" style="display: none;">
                  <select id="section-filter" class="control"><option value="">All sections</option></select>
                </div>
                <div class="toolbar-group toolbar-view-mode" style="margin-left: 6px; border-left: 1px solid var(--border); padding-left: 10px; gap: 4px;">
                  <button id="view-diagram" class="system-btn active" type="button">Diagram</button>
                  <button id="view-list" class="system-btn" type="button">Docs</button>
                </div>
                <div class="toolbar-group toolbar-zoom">
                  <button id="zoom-out" class="system-btn icon-btn" type="button" title="Zoom out" aria-label="Zoom out">
                    <svg width="14" height="14" viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round"><path d="M3 8h10"/></svg>
                  </button>
                  <span id="zoom-level" class="zoom-label">100%</span>
                  <button id="zoom-in" class="system-btn icon-btn" type="button" title="Zoom in" aria-label="Zoom in">
                    <svg width="14" height="14" viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round"><path d="M8 3v10M3 8h10"/></svg>
                  </button>
                  <button id="zoom-fit" class="system-btn" type="button">Fit</button>
                </div>
                <div class="toolbar-group toolbar-actions">
                  <button id="theme-toggle" class="system-btn icon-btn" type="button" title="Toggle theme" aria-label="Toggle light or dark theme"></button>
                  <button id="export-png" class="system-btn" type="button">
                    <span class="btn-icon" aria-hidden="true">
                      <svg width="14" height="14" viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round"><path d="M8 2v8M5 7.5l3 3 3-3M3 13h10"/></svg>
                    </span> Export PNG
                  </button>
                </div>
                <div class="toolbar-group toolbar-info">
                  <span id="stats" class="stat-pill"></span>
                </div>
              </header>

              <div class="system-body">
                <main class="canvas-wrap" id="canvas-wrap">
                  <div id="canvas" class="canvas"></div>
                  <div id="legend" class="legend collapsed">
                    <button id="legend-toggle" class="legend-toggle" type="button">Legend ▸</button>
                    <div id="legend-content" class="legend-content"></div>
                  </div>
                </main>
                <main class="stripe-docs-wrap" id="stripe-docs-wrap" style="display: none;">
                  <nav class="stripe-sidebar" id="stripe-sidebar"></nav>
                  <div class="stripe-content" id="stripe-content"></div>
                  <aside class="stripe-detail" id="stripe-detail">
                    <button class="stripe-detail-close" id="stripe-detail-close" type="button" aria-label="Close panel">
                      <svg width="15" height="15" viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"><path d="M4 4l8 8M12 4l-8 8"/></svg>
                    </button>
                    <div class="stripe-detail-body" id="stripe-detail-body">
                      <div class="stripe-detail-empty">
                        <div class="stripe-detail-empty-icon" aria-hidden="true">
                          <svg width="26" height="26" viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 1.5h6L13 5v9.5H3z"/><path d="M9 1.5V5h4"/><path d="M5.5 8.5h5M5.5 11h3"/></svg>
                        </div>
                        <p>Select an endpoint to see how to call it.</p>
                      </div>
                    </div>
                  </aside>
                </main>
                <aside id="panel" class="panel"></aside>
              </div>
            </div>
            <div id="toast" class="toast" role="status"></div>
            <script>#{SystemScript.config_script(graph_url: system_url)}</script>
            <script>#{SystemScript.javascript}</script>
          </body>
          </html>
        HTML
      end
    end
  end
end

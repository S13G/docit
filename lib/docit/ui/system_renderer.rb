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
            <style>#{SystemStyles.css}</style>
          </head>
          <body>
            #{nav_bar(active: :system)}
            <div class="system-shell">
              <header class="system-toolbar">
                <div class="toolbar-group toolbar-brand">
                  <div class="brand-mark" aria-hidden="true">◆</div>
                  <div class="toolbar-title">
                    <strong>System Architecture</strong>
                    <span>Interactive diagram · drag, zoom, explore</span>
                  </div>
                </div>
                <div class="toolbar-group toolbar-filters">
                  <input id="search" class="control" type="search" placeholder="Search nodes…" autocomplete="off">
                  <select id="type-filter" class="control"><option value="">All types</option></select>
                </div>
                <div class="toolbar-group toolbar-zoom">
                  <button id="zoom-out" class="system-btn icon-btn" type="button" title="Zoom out">−</button>
                  <span id="zoom-level" class="zoom-label">100%</span>
                  <button id="zoom-in" class="system-btn icon-btn" type="button" title="Zoom in">+</button>
                  <button id="zoom-fit" class="system-btn" type="button">Fit</button>
                </div>
                <div class="toolbar-group toolbar-actions">

                  <button id="ai-explain" class="system-btn ai-btn" type="button">
                    <span class="btn-icon">✦</span> AI Explain
                  </button>
                  <button id="export-png" class="system-btn" type="button">
                    <span class="btn-icon">↓</span> Export PNG
                  </button>
                </div>
                <div class="toolbar-group toolbar-info">
                  <span id="selection-count" class="selection-badge"></span>
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
                <aside id="panel" class="panel">
                  <div class="panel-welcome">
                    <div class="welcome-icon">◆</div>
                    <h2>System Architecture</h2>
                    <p>This diagram maps your Rails application — routes, controllers, actions, models, services, and how they connect.</p>
                    <div class="welcome-tips">
                      <div class="tip"><span class="tip-icon">👆</span><span>Click a node to inspect it</span></div>
                      <div class="tip"><span class="tip-icon">✋</span><span>Drag nodes to rearrange the layout</span></div>
                      <div class="tip"><span class="tip-icon">🔍</span><span>Scroll to zoom · Shift-drag to pan</span></div>
                      <div class="tip"><span class="tip-icon">✦</span><span>Use <strong>AI Explain</strong> to understand any part of the system</span></div>
                    </div>
                  </div>
                </aside>
              </div>
            </div>
            <div id="toast" class="toast" role="status"></div>
            <script>#{SystemScript.javascript(graph_url: system_url, insights_url: system_insights_url)}</script>
          </body>
          </html>
        HTML
      end
    end
  end
end

# frozen_string_literal: true

module Docit
  module UI
    module SystemStyles
      def self.css
        <<~CSS
          :root {
            --void: #0f1117; --ink: #1a1f2e; --ember: #f5793a; --dusk: #8b5cf6;
            --haze: #7a8fb5; --smoke: #a8b4c8; --text: #f2f0ec; --border: #2a3347;
            --success: #34c759; --info: #4da6ff; --warning: #ffb340; --danger: #ff4f4f;
            --teal: #2dd4bf; --pink: #ec4899; --amber: #f59e0b;
          }
          *, *::before, *::after { box-sizing: border-box; }
          html, body { margin: 0; min-height: 100%; background: var(--void); color: var(--text); }
          body { overflow: hidden; font-family: "DM Sans", -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; }
          button, input, select { font: inherit; }

          /* Shell */
          .system-shell { display: grid; grid-template-rows: auto 1fr; height: calc(100vh - 37px); min-height: 640px; }

          /* Toolbar */
          .system-toolbar {
            display: flex; align-items: center; gap: 8px; padding: 10px 16px; flex-wrap: wrap;
            border-bottom: 1px solid var(--border); background: rgba(15,17,23,0.96);
            backdrop-filter: blur(16px) saturate(150%);
          }
          .toolbar-group { display: flex; align-items: center; gap: 6px; }
          .toolbar-brand { margin-right: auto; gap: 10px; }
          .toolbar-filters { gap: 6px; }
          .toolbar-zoom { gap: 4px; padding: 0 6px; border-left: 1px solid var(--border); border-right: 1px solid var(--border); }
          .toolbar-actions { gap: 6px; }
          .toolbar-info { gap: 8px; margin-left: 4px; }

          .brand-mark {
            width: 28px; height: 28px; border-radius: 8px; display: grid; place-items: center;
            background: linear-gradient(135deg, rgba(245,121,58,.18), rgba(139,92,246,.14));
            border: 1px solid rgba(245,121,58,.28); color: var(--ember); font-size: 14px;
          }
          .toolbar-title { min-width: 170px; }
          .toolbar-title strong {
            display: block; font-family: "Sora", -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
            font-size: 14px; letter-spacing: 0;
          }
          .toolbar-title span { color: var(--haze); font-size: 11px; }
          .stat-pill { color: var(--haze); font-size: 11px; font-family: monospace; }

          .control {
            height: 32px; border: 1px solid var(--border); border-radius: 8px;
            background: rgba(26,31,46,.86); color: var(--text); padding: 0 10px; outline: none;
            font-size: 12px; min-width: 0;
          }
          .control:focus { border-color: rgba(245,121,58,.6); box-shadow: 0 0 0 2px rgba(245,121,58,.12); }
          input.control { width: 160px; }
          select.control { width: 120px; }

          .system-btn {
            height: 32px; border: 1px solid rgba(168,180,200,.2); border-radius: 8px;
            background: rgba(26,31,46,.6); color: var(--smoke); padding: 0 10px;
            cursor: pointer; font-size: 12px; display: flex; align-items: center; gap: 4px;
            transition: all 120ms ease;
          }
          .system-btn:hover { background: rgba(42,51,71,.8); color: var(--text); }
          .system-btn.active { background: rgba(245,121,58,.15); color: var(--ember); border-color: rgba(245,121,58,.4); }
          .system-btn.ai-btn { border-color: rgba(139,92,246,.35); color: var(--dusk); }
          .system-btn.ai-btn:hover { background: rgba(139,92,246,.12); }
          .system-btn.ai-btn.active { background: rgba(139,92,246,.2); color: #a78bfa; border-color: rgba(139,92,246,.5); }
          .icon-btn { width: 32px; justify-content: center; padding: 0; font-size: 16px; font-weight: 700; }
          .btn-icon { font-size: 13px; }
          .zoom-label { font-size: 11px; color: var(--haze); font-family: monospace; min-width: 38px; text-align: center; }

          .selection-badge {
            display: none; padding: 2px 8px; border-radius: 99px; font-size: 11px; font-weight: 600;
            background: rgba(139,92,246,.18); color: #a78bfa; border: 1px solid rgba(139,92,246,.3);
          }
          .selection-badge.visible { display: inline-block; }

          /* Body */
          .system-body { display: grid; grid-template-columns: 1fr 400px; min-height: 0; overflow: hidden; }

          /* Canvas */
          .canvas-wrap {
            position: relative; height: 100%; min-height: 0; overflow: hidden; cursor: grab;
            background:
              radial-gradient(circle at 25px 25px, rgba(168,180,200,.06) 1px, transparent 1px),
              radial-gradient(ellipse 800px 600px at 30% 20%, rgba(245,121,58,.04), transparent 60%),
              radial-gradient(ellipse 700px 500px at 70% 80%, rgba(139,92,246,.04), transparent 60%),
              var(--void);
            background-size: 30px 30px, auto, auto, auto;
          }
          .canvas-wrap.panning,
          .canvas-wrap:active { cursor: grabbing; }
          .canvas { width: 100%; height: 100%; position: absolute; top: 0; left: 0; }
          .canvas svg { display: block; width: 100%; height: 100%; overflow: visible; }

          /* Nodes — hover & interaction */
          .canvas svg .node { cursor: grab; transition: filter 180ms ease; }
          .canvas svg .node:active { cursor: grabbing; }
          .canvas svg .node:hover rect:first-of-type {
            stroke-opacity: 0.7 !important;
            filter: drop-shadow(0 6px 16px rgba(0,0,0,0.35));
          }
          .canvas svg .node.selected rect:first-of-type {
            filter: drop-shadow(0 8px 24px rgba(245,121,58,0.18));
          }
          .canvas svg .node.ai-picked rect:first-of-type {
            filter: drop-shadow(0 8px 24px rgba(139,92,246,0.22));
          }
          .canvas svg .swimlane { pointer-events: none; }
          .canvas svg path[marker-end] { transition: opacity 180ms ease, stroke-width 180ms ease; }
          .canvas svg path[marker-end]:hover { opacity: 1 !important; stroke-width: 2.2 !important; }

          /* Legend */
          .legend {
            position: absolute; bottom: 16px; left: 16px; z-index: 10;
            background: rgba(15,17,23,.95); border: 1px solid var(--border); border-radius: 12px;
            backdrop-filter: blur(12px); max-width: 200px; overflow: hidden;
            transition: max-height 200ms ease;
          }
          .legend.collapsed .legend-content { display: none; }
          .legend-toggle {
            display: block; width: 100%; padding: 8px 12px; border: 0; background: transparent;
            color: var(--haze); font-size: 11px; font-family: monospace; cursor: pointer; text-align: left;
          }
          .legend-toggle:hover { color: var(--text); }
          .legend-content { padding: 0 12px 10px; }
          .legend-section { margin-bottom: 8px; }
          .legend-heading { font-size: 10px; color: var(--haze); text-transform: uppercase; letter-spacing: .06em; margin-bottom: 4px; font-family: monospace; }
          .legend-item { display: flex; align-items: center; gap: 8px; padding: 2px 0; font-size: 11px; color: var(--smoke); }
          .legend-dot { width: 8px; height: 8px; border-radius: 50%; flex-shrink: 0; }
          .legend-line { width: 16px; height: 2px; border-radius: 1px; background: var(--haze); flex-shrink: 0; }

          /* Panel */
          .panel {
            border-left: 1px solid var(--border); background: rgba(15,17,23,.97);
            overflow-y: auto; overflow-x: hidden; scrollbar-width: thin;
            scrollbar-color: var(--border) transparent;
          }

          .panel-welcome {
            margin: 20px 16px; padding: 24px 20px; border: 1px solid var(--border); border-radius: 16px;
            background: linear-gradient(145deg, rgba(26,31,46,.8), rgba(15,17,23,.6));
            text-align: center;
          }
          .welcome-icon {
            width: 48px; height: 48px; border-radius: 14px; display: inline-grid; place-items: center;
            background: linear-gradient(135deg, rgba(245,121,58,.15), rgba(139,92,246,.12));
            border: 1px solid rgba(245,121,58,.25); color: var(--ember); font-size: 22px; margin-bottom: 14px;
          }
          .panel-welcome h2 {
            margin: 0 0 8px; font-family: "Sora", -apple-system, BlinkMacSystemFont, sans-serif;
            font-size: 17px; font-weight: 700;
          }
          .panel-welcome p { margin: 0 0 18px; color: var(--haze); font-size: 13px; line-height: 1.5; }
          .welcome-tips { text-align: left; }
          .tip {
            display: flex; align-items: flex-start; gap: 10px; padding: 8px 0;
            border-bottom: 1px solid rgba(42,51,71,.5); font-size: 12px; color: var(--smoke); line-height: 1.4;
          }
          .tip:last-child { border-bottom: 0; }
          .tip-icon { font-size: 14px; flex-shrink: 0; width: 20px; text-align: center; }
          .tip strong { color: var(--ember); }

          .panel-empty, .panel-section {
            margin: 16px; border: 1px solid var(--border); border-radius: 14px; background: rgba(26,31,46,.6);
          }
          .panel-empty { padding: 20px; color: var(--haze); font-size: 13px; line-height: 1.5; }

          .panel-section { overflow: hidden; }
          .panel-section h2 {
            margin: 0; padding: 16px 18px 6px;
            font-family: "Sora", -apple-system, BlinkMacSystemFont, sans-serif;
            font-size: 15px; letter-spacing: 0; font-weight: 700;
          }
          .panel-section h3 {
            margin: 0; padding: 12px 18px 4px; font-size: 12px; color: var(--haze);
            text-transform: uppercase; letter-spacing: .04em; font-family: monospace;
          }
          .panel-section dl { margin: 0; padding: 6px 18px 18px; }
          .panel-section dt {
            margin-top: 14px; color: var(--haze); font-size: 11px; font-family: monospace;
            text-transform: uppercase; letter-spacing: .04em;
          }
          .panel-section dd { margin: 4px 0 0; color: var(--smoke); font-size: 13px; word-break: break-word; line-height: 1.5; }
          .panel-section pre {
            overflow-x: auto; margin: 0; padding: 12px; border-radius: 8px; background: rgba(15,17,23,.6);
            color: var(--smoke); font-size: 11px; white-space: pre-wrap; line-height: 1.5;
          }

          /* AI panel */
          .ai-panel-header {
            padding: 18px 18px 10px; border-bottom: 1px solid var(--border);
          }
          .ai-panel-header h2 {
            margin: 0 0 4px; font-family: "Sora", -apple-system, BlinkMacSystemFont, sans-serif;
            font-size: 15px; font-weight: 700;
          }
          .ai-panel-header p { margin: 0; color: var(--haze); font-size: 12px; line-height: 1.4; }

          .ai-category {
            padding: 8px 18px 0;
          }
          .ai-category-title {
            font-size: 10px; color: var(--haze); text-transform: uppercase; letter-spacing: .06em;
            font-family: monospace; margin-bottom: 4px; padding-top: 8px;
            border-top: 1px solid rgba(42,51,71,.5);
          }
          .ai-category:first-of-type .ai-category-title { border-top: 0; }

          .ai-option {
            display: flex; gap: 10px; align-items: flex-start; padding: 7px 0; cursor: pointer;
            font-size: 12px; transition: background 80ms;
          }
          .ai-option:hover { background: rgba(42,51,71,.3); margin: 0 -18px; padding: 7px 18px; }
          .ai-option input[type="checkbox"] { margin-top: 2px; accent-color: var(--dusk); cursor: pointer; flex-shrink: 0; }
          .ai-option-info { min-width: 0; }
          .ai-option-label { color: var(--text); font-weight: 500; display: block; }
          .ai-option-meta { color: var(--haze); font-size: 10px; font-family: monospace; display: block; margin-top: 1px; }
          .ai-option-dot {
            display: inline-block; width: 6px; height: 6px; border-radius: 50%; margin-right: 4px; vertical-align: middle;
          }

          .ai-generate-bar {
            position: sticky; bottom: 0; padding: 12px 18px;
            background: rgba(15,17,23,.96); border-top: 1px solid var(--border);
            backdrop-filter: blur(8px);
          }
          .ai-generate-btn {
            width: 100%; height: 38px; border: 1px solid rgba(139,92,246,.4); border-radius: 10px;
            background: linear-gradient(135deg, rgba(139,92,246,.15), rgba(245,121,58,.08));
            color: #a78bfa; font-size: 13px; font-weight: 600; cursor: pointer;
            transition: all 150ms ease;
          }
          .ai-generate-btn:hover { background: linear-gradient(135deg, rgba(139,92,246,.25), rgba(245,121,58,.12)); }
          .ai-generate-btn:disabled { opacity: 0.5; cursor: not-allowed; }
          .ai-generate-btn.loading {
            color: var(--haze); border-color: var(--border);
            background: rgba(26,31,46,.6);
          }

          /* AI results */
          .ai-result { padding: 18px; }
          .ai-result-section { margin-bottom: 16px; }
          .ai-result-section:last-child { margin-bottom: 0; }
          .ai-result-heading {
            display: flex; align-items: center; gap: 6px; font-size: 13px; font-weight: 700;
            color: var(--text); margin-bottom: 8px;
          }
          .ai-result-heading .icon { color: var(--ember); }
          .ai-result-body { color: var(--smoke); font-size: 12px; line-height: 1.6; }
          .ai-result-body p { margin: 0 0 8px; }
          .ai-back-btn {
            display: inline-flex; align-items: center; gap: 4px; border: 0; background: transparent;
            color: var(--haze); font-size: 12px; cursor: pointer; padding: 0; margin-bottom: 12px;
          }
          .ai-back-btn:hover { color: var(--ember); }

          /* Node detail in panel */
          .node-detail-header {
            display: flex; align-items: center; gap: 10px; padding: 16px 18px;
            border-bottom: 1px solid var(--border);
          }
          .node-detail-badge {
            width: 36px; height: 36px; border-radius: 10px; display: grid; place-items: center;
            font-size: 16px; flex-shrink: 0;
          }
          .node-detail-title { font-size: 15px; font-weight: 700; word-break: break-word; }
          .node-detail-type { font-size: 11px; color: var(--haze); font-family: monospace; display: flex; align-items: center; gap: 4px; flex-wrap: wrap; }
          .node-fact {
            display: inline-block; padding: 1px 6px; border-radius: 4px; font-size: 10px;
            background: rgba(168,180,200,.1); color: var(--smoke); font-family: monospace; font-weight: 600;
          }

          /* Edge line in panel */
          .edge-line {
            display: flex; justify-content: space-between; align-items: flex-start; gap: 8px;
            border-bottom: 1px solid rgba(42,51,71,.5); padding: 8px 0; font-size: 12px;
          }
          .edge-line:last-child { border-bottom: 0; }
          .edge-line-info { color: var(--smoke); line-height: 1.4; }
          .edge-line-type { font-weight: 600; color: var(--text); }
          .edge-line button {
            flex-shrink: 0; border: 0; background: transparent; color: var(--ember);
            cursor: pointer; font-size: 11px; padding: 2px 4px;
          }
          .edge-line button:hover { text-decoration: underline; }

          /* Connection items in detail panel */
          .connection-item {
            display: flex; align-items: flex-start; gap: 8px; padding: 8px 0;
            border-bottom: 1px solid rgba(42,51,71,.4); font-size: 12px;
          }
          .connection-item:last-child { border-bottom: 0; }
          .connection-arrow { font-size: 14px; flex-shrink: 0; margin-top: 1px; font-weight: 600; }
          .connection-info { flex: 1; min-width: 0; }
          .connection-verb { display: block; color: var(--smoke); font-size: 11px; line-height: 1.4; }
          .connection-label { display: block; color: var(--text); font-weight: 600; font-size: 12px; word-break: break-word; }
          .connection-type { color: var(--haze); font-size: 10px; font-family: monospace; }
          .connection-remove {
            flex-shrink: 0; width: 20px; height: 20px; border: 0; border-radius: 4px;
            background: transparent; color: var(--haze); cursor: pointer; font-size: 14px;
            display: grid; place-items: center; opacity: 0; transition: opacity 120ms;
          }
          .connection-item:hover .connection-remove { opacity: 1; }
          .connection-remove:hover { color: var(--ember); background: rgba(245,121,58,.1); }

          /* Controller detail — action list */
          .action-summary {
            padding: 10px 0; border-bottom: 1px solid rgba(42,51,71,.4);
          }
          .action-summary:last-child { border-bottom: 0; }
          .action-summary-name {
            font-size: 13px; font-weight: 600; color: var(--text); margin-bottom: 4px;
            display: flex; align-items: center; gap: 6px;
          }
          .action-doc-badge {
            font-size: 9px; font-weight: 700; font-family: monospace;
            padding: 1px 5px; border-radius: 3px;
            background: rgba(52,199,89,.12); color: #34c759; border: 1px solid rgba(52,199,89,.2);
            text-transform: uppercase; letter-spacing: .04em;
          }
          .action-summary-route {
            margin: 4px 0; display: flex; align-items: center; gap: 6px; flex-wrap: wrap;
          }
          .action-summary-desc {
            font-size: 12px; color: var(--smoke); line-height: 1.4; margin: 4px 0;
          }
          .action-summary-responses {
            display: flex; gap: 4px; margin-top: 4px; flex-wrap: wrap;
          }
          .response-code {
            font-size: 10px; font-family: monospace; font-weight: 600;
            padding: 1px 6px; border-radius: 3px;
            background: rgba(168,180,200,.08); color: var(--haze); border: 1px solid rgba(168,180,200,.12);
          }
          .response-code[data-status^="2"] { background: rgba(52,199,89,.1); color: #34c759; border-color: rgba(52,199,89,.2); }
          .response-code[data-status^="4"] { background: rgba(255,79,79,.1); color: #ff4f4f; border-color: rgba(255,79,79,.2); }
          .response-code[data-status^="5"] { background: rgba(255,179,64,.1); color: #ffb340; border-color: rgba(255,179,64,.2); }

          /* Toast */
          .toast {
            position: fixed; left: 50%; bottom: 24px; transform: translateX(-50%); padding: 10px 16px;
            border: 1px solid rgba(245,121,58,.25); border-radius: 999px; background: rgba(26,31,46,.96);
            color: var(--ember); font-size: 12px; opacity: 0; pointer-events: none;
            transition: opacity 180ms ease; backdrop-filter: blur(8px); z-index: 100;
          }
          .toast.visible { opacity: 1; }

          /* Responsive */
          @media (max-width: 980px) {
            body { overflow: auto; }
            .system-body { grid-template-columns: 1fr; }
            .panel { min-height: 320px; border-left: 0; border-top: 1px solid var(--border); }
            input.control { width: 120px; }
            .toolbar-zoom { display: none; }
          }
        CSS
      end
    end
  end
end

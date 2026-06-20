# frozen_string_literal: true

module Docit
  module UI
    module SystemStyles
      def self.css
        <<~CSS
          /* ───────── Theme tokens ─────────
             Light is the default. [data-theme="dark"] on <html> overrides.
             Accent hues (ember / dusk / method / status) are shared by both
             themes — only the neutrals (surface, text, border) flip. */
          :root {
            /* Shared accents — identical in both themes */
            --ember: #ea6a2e; --dusk: #7c4ddb;
            --success: #1a9e4b; --info: #2563eb; --warning: #d97706; --danger: #dc2626;
            --teal: #0d9488; --pink: #db2777; --amber: #d97706;

            /* Light neutrals (default) */
            --void: #f6f7f9;            /* app background */
            --text: #1a1f2e;            /* primary text */
            --smoke: #475067;           /* secondary text */
            --haze: #6b7488;            /* tertiary / labels */
            --border: #e3e6ec;          /* hairlines */

            --bg-solid: #ffffff;        /* opaque surfaces (nodes, code) */
            --bg-glass: rgba(255,255,255,0.86);
            --bg-control: #ffffff;
            --bg-panel: #ffffff;
            --bg-card: #ffffff;
            --bg-card-grad-1: #ffffff;
            --bg-card-grad-2: #f6f7f9;
            --bg-option-hover: rgba(15,23,42,0.04);
            --grid-dot: rgba(15,23,42,0.05);
            --stripe-bg-light: #fafbfc;
            --stripe-card-bg: #ffffff;
            --stripe-bg-sidebar: #fafbfc;
            --bg-code: #f4f5f7;        /* inline + block code surface */

            color-scheme: light;
          }

          [data-theme="dark"] {
            --void: #0f1117;
            --text: #f2f0ec;
            --smoke: #a8b4c8;
            --haze: #7a8fb5;
            --border: #2a3347;

            --bg-solid: #161b28;
            --bg-glass: rgba(15,17,23,0.96);
            --bg-control: rgba(26,31,46,0.86);
            --bg-panel: rgba(15,17,23,0.97);
            --bg-card: rgba(26,31,46,0.6);
            --bg-card-grad-1: rgba(26,31,46,0.8);
            --bg-card-grad-2: rgba(15,17,23,0.6);
            --bg-option-hover: rgba(42,51,71,0.3);
            --grid-dot: rgba(168,180,200,0.06);
            --stripe-bg-light: rgba(15,17,23,.4);
            --stripe-card-bg: rgba(26,31,46,.4);
            --stripe-bg-sidebar: rgba(15,17,23,.6);
            --bg-code: rgba(26,31,46,.8);

            color-scheme: dark;
          }
          *, *::before, *::after { box-sizing: border-box; }
          html, body { margin: 0; min-height: 100%; background: var(--void); color: var(--text); }
          body { overflow: hidden; font-family: "DM Sans", -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; }
          button, input, select { font: inherit; }

          /* Inline icon alignment — SVG glyphs sit centered on the text baseline. */
          .btn-icon, .tip-icon, .welcome-icon {
            display: inline-flex; align-items: center; justify-content: center;
          }
          .btn-icon svg { vertical-align: middle; }

          /* Shell */
          .system-shell { display: grid; grid-template-rows: auto 1fr; height: calc(100vh - 37px); min-height: 640px; }

          /* Toolbar */
          .system-toolbar {
            display: flex; align-items: center; gap: 8px; padding: 10px 16px; flex-wrap: wrap;
            border-bottom: 1px solid var(--border); background: var(--bg-glass);
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
            background: var(--bg-control); color: var(--text); padding: 0 10px; outline: none;
            font-size: 12px; min-width: 0;
          }
          .control:focus { border-color: rgba(245,121,58,.6); box-shadow: 0 0 0 2px rgba(245,121,58,.12); }
          input.control { width: 160px; }
          select.control { width: 120px; }

          .system-btn {
            height: 32px; border: 1px solid rgba(168,180,200,.2); border-radius: 8px;
            background: var(--bg-card); color: var(--smoke); padding: 0 10px;
            cursor: pointer; font-size: 12px; display: flex; align-items: center; gap: 4px;
            transition: all 120ms ease;
          }
          .system-btn:hover { background: var(--bg-option-hover); color: var(--text); }
          .system-btn.active { background: rgba(245,121,58,.15); color: var(--ember); border-color: rgba(245,121,58,.4); }
          .icon-btn { width: 32px; justify-content: center; padding: 0; font-size: 16px; font-weight: 700; }
          .btn-icon { font-size: 13px; }
          .zoom-label { font-size: 11px; color: var(--haze); font-family: monospace; min-width: 38px; text-align: center; }

          /* Body */
          .system-body { display: grid; grid-template-columns: 1fr 400px; min-height: 0; overflow: hidden; }

          /* Canvas */
          .canvas-wrap {
            position: relative; height: 100%; min-height: 0; overflow: hidden; cursor: grab;
            background:
              radial-gradient(circle at 25px 25px, var(--grid-dot) 1px, transparent 1px),
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
            filter: drop-shadow(0 6px 16px rgba(15,23,42,0.14));
          }
          [data-theme="dark"] .canvas svg .node:hover rect:first-of-type {
            filter: drop-shadow(0 6px 16px rgba(0,0,0,0.35));
          }
          .canvas svg .node.selected rect:first-of-type {
            filter: drop-shadow(0 8px 24px rgba(245,121,58,0.18));
          }
          .canvas svg .swimlane { pointer-events: none; }
          .canvas svg path[marker-end] { transition: opacity 180ms ease, stroke-width 180ms ease; }
          .canvas svg path[marker-end]:hover { opacity: 1 !important; stroke-width: 2.2 !important; }

          /* Legend */
          .legend {
            position: absolute; bottom: 16px; left: 16px; z-index: 10;
            background: var(--bg-glass); border: 1px solid var(--border); border-radius: 12px;
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
            border-left: 1px solid var(--border); background: var(--bg-panel);
            overflow-y: auto; overflow-x: hidden; scrollbar-width: thin;
            scrollbar-color: var(--border) transparent;
          }

          .panel-welcome {
            margin: 20px 16px; padding: 24px 20px; border: 1px solid var(--border); border-radius: 16px;
            background: linear-gradient(145deg, var(--bg-card-grad-1), var(--bg-card-grad-2));
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
            margin: 16px; border: 1px solid var(--border); border-radius: 14px; background: var(--bg-card);
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
            overflow-x: auto; margin: 0; padding: 12px; border-radius: 8px; background: var(--bg-solid);
            color: var(--smoke); font-size: 11px; white-space: pre-wrap; line-height: 1.5;
          }

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
            border-bottom: 1px solid var(--border); padding: 8px 0; font-size: 12px;
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
            border-bottom: 1px solid var(--border); font-size: 12px;
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
            padding: 10px 0; border-bottom: 1px solid var(--border);
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
            border: 1px solid rgba(245,121,58,.25); border-radius: 999px; background: var(--bg-glass);
            color: var(--ember); font-size: 12px; opacity: 0; pointer-events: none;
            transition: opacity 180ms ease; backdrop-filter: blur(8px); z-index: 100;
          }
          .toast.visible { opacity: 1; }

          /* ───────── API documentation view ─────────
             A real docs layout: sticky resource nav on the left, a readable
             single-column reference on the right. Reads light-first. */
          .stripe-docs-wrap {
            display: grid; grid-template-columns: 260px minmax(0, 1fr) 400px;
            height: 100%; min-height: 0; overflow: hidden; background: var(--void);
          }
          .mono { font-family: "SF Mono", ui-monospace, SFMono-Regular, Menlo, monospace; }

          .stripe-sidebar {
            border-right: 1px solid var(--border); background: var(--stripe-bg-sidebar);
            padding: 28px 14px; overflow-y: auto; display: flex; flex-direction: column; gap: 26px;
            scrollbar-width: thin; scrollbar-color: var(--border) transparent;
          }
          .stripe-sidebar-group { display: flex; flex-direction: column; gap: 2px; }
          .stripe-sidebar-heading {
            font-size: 11px; font-weight: 700; color: var(--text); letter-spacing: .02em;
            margin-bottom: 8px; padding-left: 10px;
          }
          .stripe-sidebar-item {
            display: flex; align-items: center; justify-content: space-between; gap: 8px;
            padding: 7px 10px; border-radius: 8px; font-size: 12.5px; color: var(--smoke);
            text-decoration: none; transition: background 120ms ease, color 120ms ease; cursor: pointer;
            border-left: 2px solid transparent;
          }
          .stripe-sidebar-label { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
          .stripe-sidebar-item:hover { background: var(--bg-option-hover); color: var(--text); }
          .stripe-sidebar-item.active {
            background: var(--bg-option-hover); color: var(--ember); font-weight: 600;
            border-left: 2px solid var(--ember); border-radius: 0 8px 8px 0;
          }
          .stripe-sidebar-badge {
            font-size: 8px; font-weight: 800; font-family: "SF Mono", ui-monospace, monospace;
            padding: 2px 5px; border-radius: 4px; letter-spacing: .03em; flex-shrink: 0;
          }

          .stripe-content {
            padding: 44px 48px; overflow-y: auto; scroll-behavior: smooth; height: 100%;
            scrollbar-width: thin; scrollbar-color: var(--border) transparent;
          }
          .stripe-controller-block {
            margin-bottom: 64px; border-bottom: 1px solid var(--border); padding-bottom: 48px;
          }
          .stripe-controller-block:last-child { border-bottom: 0; margin-bottom: 24px; }
          .stripe-controller-header {
            display: flex; align-items: flex-start; justify-content: space-between; gap: 16px;
            margin-bottom: 4px; flex-wrap: wrap;
          }
          .stripe-controller-kicker {
            font-size: 11px; font-weight: 700; color: var(--ember); text-transform: uppercase;
            letter-spacing: .08em; margin-bottom: 4px;
          }
          .stripe-controller-title {
            margin: 0; font-family: "Sora", -apple-system, sans-serif; font-size: 26px;
            font-weight: 800; color: var(--text); letter-spacing: -0.01em;
          }
          .stripe-controller-file {
            font-size: 11px; color: var(--haze); font-family: "SF Mono", ui-monospace, monospace;
            padding: 4px 8px; background: var(--bg-option-hover); border-radius: 6px; white-space: nowrap;
          }
          .stripe-controller-sub { margin: 0 0 24px; color: var(--haze); font-size: 13px; }
          .stripe-controller-sub .mono { color: var(--smoke); }

          .stripe-controller-aside { display: flex; align-items: center; gap: 10px; flex-shrink: 0; }
          .stripe-coverage {
            font-size: 11px; font-weight: 700; padding: 4px 9px; border-radius: 999px;
            border: 1px solid; white-space: nowrap;
          }

          /* ───────── Right-hand detail panel ─────────
             Fills the third column: endpoint request/response on click. */
          .stripe-detail {
            position: relative; border-left: 1px solid var(--border); background: var(--bg-panel);
            overflow-y: auto; height: 100%; min-height: 0;
            scrollbar-width: thin; scrollbar-color: var(--border) transparent;
          }
          .stripe-detail-close {
            position: absolute; top: 14px; right: 14px; z-index: 2;
            width: 28px; height: 28px; display: none; align-items: center; justify-content: center;
            border: 1px solid var(--border); border-radius: 8px; background: var(--bg-card);
            color: var(--haze); cursor: pointer;
          }
          .stripe-detail-close:hover { color: var(--text); background: var(--bg-option-hover); }
          .stripe-detail-body { padding: 28px 24px; }

          .stripe-detail-empty {
            display: flex; flex-direction: column; align-items: center; justify-content: center;
            text-align: center; min-height: 60vh; color: var(--haze); gap: 14px;
          }
          .stripe-detail-empty-icon {
            width: 52px; height: 52px; border-radius: 14px; display: grid; place-items: center;
            background: var(--bg-option-hover); color: var(--haze);
          }
          .stripe-detail-empty p { margin: 0; font-size: 13px; line-height: 1.5; max-width: 240px; }
          .stripe-detail-empty strong { color: var(--smoke); }

          /* Detail header */
          .detail-kicker { font-size: 11px; font-weight: 700; color: var(--ember); text-transform: uppercase; letter-spacing: .07em; margin-bottom: 6px; }
          .detail-title {
            margin: 0 0 14px; font-family: "Sora", -apple-system, sans-serif; font-size: 19px;
            font-weight: 700; color: var(--text); line-height: 1.3;
          }
          .detail-endpoint-line {
            display: flex; align-items: center; gap: 10px; font-family: "SF Mono", ui-monospace, monospace;
            font-size: 12.5px; padding: 10px 12px; border: 1px solid var(--border); border-radius: 9px;
            background: var(--bg-solid); margin-bottom: 18px; flex-wrap: wrap;
          }
          .detail-endpoint-line .verb { font-weight: 800; letter-spacing: .03em; }
          .detail-endpoint-line .path { color: var(--text); word-break: break-all; }
          .detail-desc { font-size: 13.5px; line-height: 1.65; color: var(--smoke); margin-bottom: 22px; }

          /* Detail sections (Parameters, Request, Responses) */
          .detail-section { margin-bottom: 24px; }
          .detail-section-title {
            font-size: 11px; font-weight: 700; color: var(--haze); text-transform: uppercase;
            letter-spacing: .06em; margin-bottom: 10px; padding-bottom: 6px; border-bottom: 1px solid var(--border);
          }
          .detail-param {
            display: flex; flex-direction: column; gap: 2px; padding: 9px 0; border-bottom: 1px solid var(--border);
          }
          .detail-param:last-child { border-bottom: 0; }
          .detail-param-head { display: flex; align-items: center; gap: 8px; flex-wrap: wrap; }
          .detail-param-name { font-family: "SF Mono", ui-monospace, monospace; font-size: 12px; font-weight: 700; color: var(--text); }
          .detail-param-type { font-family: "SF Mono", ui-monospace, monospace; font-size: 11px; color: var(--info); }
          .detail-chip {
            font-size: 9px; font-weight: 800; font-family: "SF Mono", ui-monospace, monospace;
            padding: 1px 5px; border-radius: 4px; text-transform: uppercase; letter-spacing: .03em;
          }
          .detail-chip.req { background: rgba(220,38,38,.1); color: var(--danger); }
          .detail-chip.loc { background: var(--bg-option-hover); color: var(--haze); }
          .detail-param-desc { font-size: 12px; color: var(--smoke); line-height: 1.45; }

          .detail-code {
            margin: 0; padding: 12px 14px; border: 1px solid var(--border); border-radius: 9px;
            background: var(--bg-code); color: var(--smoke); overflow-x: auto;
            font-family: "SF Mono", ui-monospace, monospace; font-size: 11.5px; line-height: 1.6; white-space: pre;
          }

          .detail-response { padding: 9px 0; border-bottom: 1px solid var(--border); }
          .detail-response:last-child { border-bottom: 0; }
          .detail-response-head { display: flex; align-items: center; gap: 8px; margin-bottom: 3px; }
          .detail-response-desc { font-size: 12px; color: var(--smoke); line-height: 1.45; }

          .detail-error { color: var(--warning); font-size: 13px; line-height: 1.5; }

          /* Slide-over drawer on narrow screens */
          @media (max-width: 1100px) {
            .stripe-docs-wrap { grid-template-columns: 240px minmax(0, 1fr); }
            .stripe-detail {
              position: fixed; top: 0; right: 0; bottom: 0; width: min(420px, 88vw); z-index: 200;
              transform: translateX(100%); transition: transform 220ms ease;
              box-shadow: -8px 0 32px rgba(15,23,42,0.18);
            }
            .stripe-detail.open { transform: translateX(0); }
            .stripe-detail-close { display: inline-flex; }
          }

          .stripe-endpoint-card {
            background: var(--stripe-card-bg); border: 1px solid var(--border); border-radius: 14px;
            margin-bottom: 20px; padding: 24px 26px; transition: border-color 150ms, box-shadow 150ms;
            scroll-margin-top: 24px; cursor: pointer;
          }
          .stripe-endpoint-card:hover {
            border-color: var(--haze);
            box-shadow: 0 4px 20px rgba(15,23,42,0.06);
          }
          .stripe-endpoint-card.detail-active {
            border-color: var(--ember);
            box-shadow: 0 4px 20px rgba(234,106,46,0.10);
          }
          .stripe-endpoint-header {
            display: flex; align-items: flex-start; justify-content: space-between; margin-bottom: 16px; gap: 16px;
          }
          .stripe-endpoint-title-wrap { min-width: 0; }
          .stripe-endpoint-kicker {
            display: flex; align-items: center; gap: 8px; margin-bottom: 6px;
            font-size: 11px; color: var(--haze);
          }
          .stripe-endpoint-title {
            margin: 0; font-family: "Sora", -apple-system, sans-serif; font-size: 18px;
            font-weight: 700; color: var(--text); letter-spacing: -0.005em; line-height: 1.3;
          }
          .stripe-endpoint-card .stripe-endpoint-explain { flex-shrink: 0; }

          .stripe-endpoint-meta {
            display: inline-flex; align-items: center; gap: 10px;
            font-family: "SF Mono", ui-monospace, monospace; font-size: 12.5px;
            padding: 9px 14px; background: var(--bg-solid); border: 1px solid var(--border); border-radius: 9px;
            margin-bottom: 18px;
          }
          .stripe-endpoint-verb { font-weight: 800; letter-spacing: .03em; }
          .stripe-endpoint-path { color: var(--text); }

          .stripe-endpoint-desc {
            color: var(--smoke); font-size: 14px; line-height: 1.65; margin-bottom: 22px; max-width: 70ch;
          }
          .stripe-endpoint-desc--empty { color: var(--haze); font-style: italic; }

          .stripe-relations-title {
            font-size: 11px; font-weight: 700; color: var(--haze); text-transform: uppercase;
            letter-spacing: .06em; margin-bottom: 10px;
          }
          .stripe-relations-grid {
            display: grid; grid-template-columns: repeat(auto-fill, minmax(190px, 1fr)); gap: 10px;
          }
          .stripe-relation-card {
            background: var(--stripe-bg-light); border: 1px solid var(--border); border-radius: 10px;
            padding: 10px 12px; display: flex; align-items: center; gap: 10px; transition: all 120ms;
            cursor: pointer;
          }
          .stripe-relation-card:hover {
            border-color: var(--ember); background: var(--bg-option-hover);
          }
          .stripe-relation-icon {
            width: 26px; height: 26px; border-radius: 7px; display: grid; place-items: center; flex-shrink: 0;
          }
          .stripe-relation-text { min-width: 0; display: flex; flex-direction: column; }
          .stripe-relation-name {
            font-size: 12px; font-weight: 600; color: var(--text);
            overflow: hidden; text-overflow: ellipsis; white-space: nowrap;
          }
          .stripe-relation-type {
            font-size: 10px; color: var(--haze); font-family: "SF Mono", ui-monospace, monospace;
          }

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

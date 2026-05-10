# frozen_string_literal: true

module Docit
  module UI
    module SystemScript
      def self.javascript(graph_url:, insights_url:)
        <<~JS
          (function() {
          "use strict";

          /* ───────────────────────── Configuration ───────────────────────── */

          const graphUrl  = #{JSON.generate(graph_url)};
          const insightsUrl = #{JSON.generate(insights_url)};

          const TYPE_COLORS = {
            route:      "#4da6ff",
            controller: "#8b5cf6",
            action:     "#f5793a",
            doc:        "#34c759",
            schema:     "#2dd4bf",
            model:      "#ff4f4f",
            service:    "#ffb340",
            job:        "#f59e0b",
            mailer:     "#ec4899"
          };

          /* SVG path icons — 16×16 box, rendered with <g transform="translate(…)"> */
          const TYPE_ICON_SVG = {
            route:      '<path d="M2,8 H13 M9,4.5 L13,8 L9,11.5" stroke="currentColor" stroke-width="1.6" fill="none" stroke-linecap="round" stroke-linejoin="round"/>',
            controller: '<rect x="2" y="3" width="12" height="10" rx="2" stroke="currentColor" stroke-width="1.5" fill="none"/><line x1="2" y1="7" x2="14" y2="7" stroke="currentColor" stroke-width="1.2" stroke-opacity="0.6"/>',
            action:     '<polygon points="4,3 4,13 13,8" stroke="currentColor" stroke-width="1.2" fill="currentColor" fill-opacity="0.25"/>',
            doc:        '<path d="M3,1 H10 L13,4 V15 H3 Z M10,1 V4 H13" stroke="currentColor" stroke-width="1.3" fill="none" stroke-linecap="round" stroke-linejoin="round"/><line x1="5" y1="8" x2="11" y2="8" stroke="currentColor" stroke-width="1.2" stroke-opacity="0.7"/><line x1="5" y1="11" x2="9" y2="11" stroke="currentColor" stroke-width="1.2" stroke-opacity="0.7"/>',
            schema:     '<rect x="1" y="1" width="6" height="6" rx="1.5" stroke="currentColor" stroke-width="1.3" fill="none"/><rect x="9" y="1" width="6" height="6" rx="1.5" stroke="currentColor" stroke-width="1.3" fill="none"/><rect x="1" y="9" width="6" height="6" rx="1.5" stroke="currentColor" stroke-width="1.3" fill="none"/><rect x="9" y="9" width="6" height="6" rx="1.5" stroke="currentColor" stroke-width="1.3" fill="none"/>',
            model:      '<ellipse cx="8" cy="4.5" rx="5" ry="2.5" stroke="currentColor" stroke-width="1.3" fill="none"/><path d="M3,4.5 v7 M13,4.5 v7" stroke="currentColor" stroke-width="1.3"/><ellipse cx="8" cy="11.5" rx="5" ry="2.5" stroke="currentColor" stroke-width="1.3" fill="none"/><ellipse cx="8" cy="8" rx="5" ry="2.5" stroke="currentColor" stroke-width="1.2" fill="none" stroke-opacity="0.4"/>',
            service:    '<circle cx="8" cy="8" r="5.5" stroke="currentColor" stroke-width="1.3" fill="none"/><circle cx="8" cy="8" r="2" stroke="currentColor" stroke-width="1.3" fill="none"/>',
            job:        '<circle cx="8" cy="8" r="5.5" stroke="currentColor" stroke-width="1.3" fill="none"/><line x1="8" y1="3.5" x2="8" y2="8" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/><line x1="8" y1="8" x2="11" y2="10.5" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/>',
            mailer:     '<rect x="1.5" y="4" width="13" height="9" rx="1.5" stroke="currentColor" stroke-width="1.3" fill="none"/><path d="M1.5,5 L8,9.5 L14.5,5" stroke="currentColor" stroke-width="1.2" fill="none"/>'
          };

          const TYPE_DESCRIPTIONS = {
            route:      "HTTP entrypoint — the URL pattern that browsers and clients hit.",
            controller: "Rails controller — groups related actions that handle requests.",
            action:     "A single controller method — processes one specific request.",
            doc:        "Docit documentation block — describes what an endpoint expects and returns.",
            schema:     "Reusable data shape — defines the structure of request/response objects.",
            model:      "Database-backed model — represents a table and its relationships.",
            service:    "Service object — encapsulates business logic outside controllers.",
            job:        "Background job — runs asynchronous work (emails, processing, etc.).",
            mailer:     "Mailer — sends emails from the application."
          };

          const METHOD_COLORS = {
            GET: "#34c759", POST: "#4da6ff", PUT: "#ffb340",
            PATCH: "#f59e0b", DELETE: "#ff4f4f"
          };

          const EDGE_COLORS = {
            routes_to: "#4da6ff", contains: "#6b7a94", documents: "#34c759",
            association: "#ff4f4f", uses_model: "#ffb340", calls: "#f59e0b", manual: "#f5793a"
          };

          const NODE_W   = 280;
          const NODE_H   = 100;
          const HEADER_H = 38;
          const COL_GAP  = 340;
          const ROW_GAP  = 134;
          const COL_ORDER = ["doc","route","action","controller","schema","model","service","job","mailer"];

          /* ───────────────────────── State ───────────────────────── */

          let graph        = { nodes: [], edges: [], stats: {} };
          let positions    = {};
          let selectedId   = null;
          let aiMode       = false;
          let aiSelection  = new Set();
          let dragState    = null;
          let panState     = null;
          let zoom         = { scale: 1, tx: 0, ty: 0 };

          /* ───────────────────────── DOM refs ───────────────────────── */

          const $  = (id) => document.getElementById(id);
          const canvas     = $("canvas");
          const canvasWrap = $("canvas-wrap");
          const panel      = $("panel");
          const searchEl   = $("search");
          const typeFilter = $("type-filter");
          const statsEl    = $("stats");
          const exportBtn  = $('export-png');
          const aiBtn      = $("ai-explain");
          const selBadge   = $("selection-count");
          const toastEl    = $("toast");
          const zoomInBtn  = $("zoom-in");
          const zoomOutBtn = $("zoom-out");
          const zoomFitBtn = $("zoom-fit");
          const zoomLabel  = $("zoom-level");
          const legendEl   = $("legend");
          const legendToggle  = $("legend-toggle");
          const legendContent = $("legend-content");

          /* ───────────────────────── Init ───────────────────────── */

          fetch(graphUrl)
            .then(function(r) { return r.json(); })
            .then(function(data) {
              graph = data;
              buildFilters();
              buildLegend();
              positions = layoutNodes(graph.nodes);
              render();
              setTimeout(zoomToFit, 60);
            })
            .catch(function(err) {
              canvas.innerHTML = '<div class="panel-empty">Unable to load system graph: ' + esc(err.message) + '</div>';
            });

          /* ───────────────────────── Events ───────────────────────── */

          searchEl.addEventListener("input", render);
          typeFilter.addEventListener("change", render);
          /* connect mode removed */
          exportBtn.addEventListener("click", exportPng);
          aiBtn.addEventListener("click", toggleAiMode);
          zoomInBtn.addEventListener("click", function() { applyZoom(1.3); });
          zoomOutBtn.addEventListener("click", function() { applyZoom(0.77); });
          zoomFitBtn.addEventListener("click", zoomToFit);
          legendToggle.addEventListener("click", toggleLegendPanel);

          /* Scroll-wheel zoom */
          canvasWrap.addEventListener("wheel", function(e) {
            e.preventDefault();
            var factor = e.deltaY < 0 ? 1.1 : 0.91;
            var rect = canvasWrap.getBoundingClientRect();
            var mx = e.clientX - rect.left;
            var my = e.clientY - rect.top;
            zoomAtPoint(mx, my, factor);
          }, { passive: false });

          /* Canvas panning — drag empty space to pan, or shift/middle-click anywhere */
          canvasWrap.addEventListener("pointerdown", function(e) {
            /* If clicking on a node element, let the node's drag handler take over */
            if (!e.shiftKey && e.button !== 1 && e.target.closest(".node")) return;
            if (e.button !== 0 && e.button !== 1) return;

            e.preventDefault();
            panState = { sx: e.clientX, sy: e.clientY, stx: zoom.tx, sty: zoom.ty, moved: false };
            canvasWrap.setPointerCapture(e.pointerId);
            canvasWrap.classList.add("panning");
          });
          canvasWrap.addEventListener("pointermove", function(e) {
            if (!panState) return;
            var dx = e.clientX - panState.sx;
            var dy = e.clientY - panState.sy;
            if (Math.abs(dx) + Math.abs(dy) > 3) panState.moved = true;
            zoom.tx = panState.stx + dx;
            zoom.ty = panState.sty + dy;
            render();
          });
          canvasWrap.addEventListener("pointerup", function() {
            panState = null;
            canvasWrap.classList.remove("panning");
          });
          canvasWrap.addEventListener("pointercancel", function() {
            panState = null;
            canvasWrap.classList.remove("panning");
          });

          /* Panel delegation — edge removal + AI checkboxes */
          panel.addEventListener("click", function(e) {
            var edgeBtn = e.target.closest("button[data-edge]");
            if (edgeBtn) {
              graph.edges = graph.edges.filter(function(edge) { return edge.id !== edgeBtn.dataset.edge; });
              if (selectedId) showNodeDetail(selectedId);
              render();
              return;
            }
            var aiCheck = e.target.closest("input[data-ai-node]");
            if (aiCheck) {
              toggleAiSelection(aiCheck.dataset.aiNode);
              return;
            }
            var genBtn = e.target.closest("#ai-generate-btn");
            if (genBtn) {
              generateAiInsight();
              return;
            }
            var backBtn = e.target.closest("#ai-back-btn");
            if (backBtn) {
              showAiSelectionPanel();
              return;
            }
          });

          /* ───────────────────────── Filters & Layout ───────────────────────── */

          function buildFilters() {
            var types = uniqueSorted(graph.nodes.map(function(n) { return n.type; }));
            types.forEach(function(t) {
              var opt = document.createElement("option");
              opt.value = t;
              opt.textContent = t;
              typeFilter.appendChild(opt);
            });
          }

          function visibleGraph() {
            var q = searchEl.value.toLowerCase();
            var t = typeFilter.value;
            var nodes = graph.nodes.filter(function(n) {
              return (!t || n.type === t) && (!q || n.label.toLowerCase().indexOf(q) !== -1);
            });
            var ids = new Set(nodes.map(function(n) { return n.id; }));
            var edges = graph.edges.filter(function(e) { return ids.has(e.source) && ids.has(e.target); });
            return { nodes: nodes, edges: edges };
          }

          function layoutNodes(nodes) {
            var groups = {};
            nodes.forEach(function(n) { (groups[n.type] = groups[n.type] || []).push(n); });
            var pos = {};
            var order = COL_ORDER.concat(Object.keys(groups).filter(function(t) { return COL_ORDER.indexOf(t) === -1; }));
            order.forEach(function(type, col) {
              (groups[type] || []).forEach(function(node, row) {
                pos[node.id] = { x: 100 + col * COL_GAP, y: 120 + row * ROW_GAP };
              });
            });
            return pos;
          }

          /* ───────────────────────── Zoom & Pan ───────────────────────── */

          function applyZoom(factor) {
            var rect = canvasWrap.getBoundingClientRect();
            zoomAtPoint(rect.width / 2, rect.height / 2, factor);
          }

          function zoomAtPoint(cx, cy, factor) {
            var prev = zoom.scale;
            zoom.scale = Math.min(4, Math.max(0.15, zoom.scale * factor));
            var ratio = zoom.scale / prev;
            zoom.tx = cx - ratio * (cx - zoom.tx);
            zoom.ty = cy - ratio * (cy - zoom.ty);
            render();
          }

          function zoomToFit() {
            var current = visibleGraph();
            if (current.nodes.length === 0) return;
            var b = graphBounds(current.nodes);
            var rect = canvasWrap.getBoundingClientRect();
            var pad = 80;
            var sx = (rect.width - pad * 2) / b.w;
            var sy = (rect.height - pad * 2) / b.h;
            zoom.scale = Math.min(1.2, Math.max(0.15, Math.min(sx, sy)));
            zoom.tx = pad - b.x * zoom.scale + (rect.width - pad * 2 - b.w * zoom.scale) / 2;
            zoom.ty = pad - b.y * zoom.scale + (rect.height - pad * 2 - b.h * zoom.scale) / 2;
            render();
          }

          function graphBounds(nodes) {
            var xs = [], ys = [];
            nodes.forEach(function(n) {
              var p = positions[n.id];
              if (p) { xs.push(p.x); ys.push(p.y); }
            });
            if (xs.length === 0) return { x: 0, y: 0, w: 800, h: 600 };
            var minX = Math.min.apply(null, xs) - 40;
            var minY = Math.min.apply(null, ys) - 60;
            var maxX = Math.max.apply(null, xs) + NODE_W + 40;
            var maxY = Math.max.apply(null, ys) + NODE_H + 40;
            return { x: minX, y: minY, w: Math.max(400, maxX - minX), h: Math.max(300, maxY - minY) };
          }

          /* ───────────────────────── Rendering ───────────────────────── */

          function render() {
            var current = visibleGraph();
            statsEl.textContent = current.nodes.length + " nodes \\u00b7 " + current.edges.length + " edges";
            selBadge.textContent = aiSelection.size > 0 ? aiSelection.size + " selected" : "";
            selBadge.classList.toggle("visible", aiSelection.size > 0);
            zoomLabel.textContent = Math.round(zoom.scale * 100) + "%";

            if (current.nodes.length === 0) {
              canvas.innerHTML = '<div class="panel-empty">No nodes match current filters.</div>';
              return;
            }
            canvas.innerHTML = buildSVG(current);
            bindNodes();
          }

          function buildSVG(data) {
            var nodes = data.nodes;
            var edges = data.edges;
            return '<svg id="system-svg" role="img" aria-label="System architecture diagram" ' +
              'width="100%" height="100%" xmlns="http://www.w3.org/2000/svg">' +
              '<defs>' +
                '<marker id="arrow" markerWidth="10" markerHeight="7" refX="9" refY="3.5" orient="auto">' +
                  '<polygon points="0 0, 10 3.5, 0 7" fill="#7a8fb5"/>' +
                '</marker>' +
                '<filter id="glow"><feGaussianBlur stdDeviation="3" result="b"/>' +
                  '<feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge></filter>' +
              '</defs>' +
              '<g id="zoom-group" transform="translate(' + zoom.tx + ',' + zoom.ty + ') scale(' + zoom.scale + ')">' +
                renderSwimlanes(nodes) + renderEdges(edges) + renderNodes(nodes) +
              '</g></svg>';
          }

          function renderSwimlanes(nodes) {
            var types = uniqueSorted(nodes.map(function(n) { return n.type; }));
            return types.map(function(type) {
              var typeNodes = nodes.filter(function(n) { return n.type === type; });
              var pxs = [], pys = [];
              typeNodes.forEach(function(n) {
                var p = positions[n.id];
                if (p) { pxs.push(p.x); pys.push(p.y); }
              });
              if (pxs.length === 0) return "";
              var minX = Math.min.apply(null, pxs);
              var minY = Math.min.apply(null, pys);
              var maxY = Math.max.apply(null, pys);
              var c = TYPE_COLORS[type] || "#7a8fb5";
              var count = typeNodes.length;
              return '<g class="swimlane">' +
                /* Lane background */
                '<rect x="' + (minX - 24) + '" y="' + (minY - 50) + '" width="' + (NODE_W + 48) + '" height="' + (maxY - minY + NODE_H + 70) + '" ' +
                  'rx="20" fill="' + c + '" fill-opacity="0.025" stroke="' + c + '" stroke-opacity="0.06" stroke-width="1"/>' +
                /* Lane label pill */
                '<rect x="' + (minX - 4) + '" y="' + (minY - 32) + '" width="' + Math.max(80, type.length * 9 + 30) + '" height="22" rx="11" ' +
                  'fill="' + c + '" fill-opacity="0.1" stroke="' + c + '" stroke-opacity="0.18"/>' +
                '<text x="' + (minX + 8) + '" y="' + (minY - 17) + '" fill="' + c + '" font-size="10" font-weight="700" ' +
                  'font-family="monospace" letter-spacing="0.1em">' + esc(type.toUpperCase()) + '</text>' +
                '<text x="' + (minX + Math.max(80, type.length * 9 + 30) - 18) + '" y="' + (minY - 17) + '" fill="' + c + '" font-size="10" font-weight="600" ' +
                  'font-family="monospace" opacity="0.6">' + count + '</text>' +
              '</g>';
            }).join("");
          }

          function renderEdges(edges) {
            return edges.map(function(edge) {
              var s = positions[edge.source];
              var t = positions[edge.target];
              if (!s || !t) return "";

              var x1 = s.x + NODE_W;
              var y1 = s.y + NODE_H / 2;
              var x2 = t.x;
              var y2 = t.y + NODE_H / 2;
              var sourceIsRight = false;

              /* If target is to the left, connect from left side of source to right side of target */
              if (s.x > t.x + NODE_W) {
                x1 = s.x;
                x2 = t.x + NODE_W;
                sourceIsRight = true;
              } else if (Math.abs(s.x - t.x) < NODE_W && s.y !== t.y) {
                /* Same column — curve via side */
                x1 = s.x + NODE_W;
                x2 = t.x + NODE_W;
              }

              var dist = Math.abs(x2 - x1);
              var mid = Math.max(60, Math.min(dist / 2, 200));
              var cx1 = sourceIsRight ? x1 - mid : x1 + mid;
              var cx2 = sourceIsRight ? x2 + mid : x2 - mid;
              var d = "M" + x1 + "," + y1 + " C" + cx1 + "," + y1 + " " + cx2 + "," + y2 + " " + x2 + "," + y2;

              var conf = edge.confidence || "medium";
              var color = EDGE_COLORS[edge.type] || "#7a8fb5";
              var dash = conf === "manual" ? "6,4" : (edge.type === "documents" ? "4,3" : "none");
              var opacity = aiDimEdge(edge) ? 0.07 : 0.45;
              var width = conf === "high" ? 1.6 : 1.2;

              return '<path d="' + d + '" stroke="' + color + '" stroke-width="' + width + '" fill="none" ' +
                'stroke-dasharray="' + dash + '" opacity="' + opacity + '" marker-end="url(#arrow)">' +
                '<title>' + esc(edge.type) + ': ' + esc(edge.evidence || "") + '</title></path>';
            }).join("");
          }

          function renderNodes(nodes) {
            return nodes.map(function(node) {
              var pos = positions[node.id];
              if (!pos) return "";
              var status = node.status || "unknown";
              var isSel = node.id === selectedId;
              var isAi = aiSelection.has(node.id);
              var dimmed = aiDimNode(node.id);
              var tc = TYPE_COLORS[node.type] || "#7a8fb5";
              var sc = status === "documented" ? "#34c759" : status === "undocumented" ? "#ffb340" : "#7a8fb5";

              var cls = "node " + esc(node.type);
              if (isSel) cls += " selected";
              if (isAi) cls += " ai-picked";

              var opacity = dimmed ? 0.14 : 1;
              var strokeW = isSel || isAi ? 2 : 1.2;
              var strokeOp = isSel ? 1 : isAi ? 0.9 : 0.32;
              var dashArr = isAi ? "6,4" : "";
              var filter = isSel ? ' filter="url(#glow)"' : "";

              /* Header band path — rounded top corners, flat bottom */
              var headerPath = "M14,0 L" + (NODE_W - 14) + ",0 A14,14 0 0 1 " + NODE_W + ",14 L" + NODE_W + "," + HEADER_H + " L0," + HEADER_H + " L0,14 A14,14 0 0 1 14,0 Z";

              /* ---- Per-type layout decisions ---- */
              var badge = "";
              var titleX = 38;  /* default: icon (14×16) at x=8 → title at x=38 */
              var label;
              var line1 = ""; /* body first line */
              var line2 = ""; /* body second line */
              var showStatusDot = false;

              if (node.type === "route") {
                /* Route: just the path in header + method badge on right, no body lines */
                titleX = 14;
                var routeMethod = node.metadata ? (node.metadata.method || "").toUpperCase() : "";
                var routePath = node.metadata && node.metadata.path ? node.metadata.path : node.label;
                label = truncate(routePath, routeMethod ? 18 : 26);
                if (routeMethod) {
                  var mc = METHOD_COLORS[routeMethod] || "#7a8fb5";
                  badge = '<rect x="' + (NODE_W - 64) + '" y="9" width="48" height="20" rx="5" fill="' + mc + '" fill-opacity="0.18"/>' +
                    '<text x="' + (NODE_W - 40) + '" y="23" text-anchor="middle" fill="' + mc + '" font-size="9" font-weight="700" font-family="monospace" letter-spacing="0.04em">' + routeMethod + '</text>';
                }
                /* no body lines for routes */

              } else if (node.type === "action") {
                /* Action: just the function name in header, HTTP method+path in body */
                label = node.metadata && node.metadata.action ? node.metadata.action : truncate(node.label, 20);
                if (node.metadata && node.metadata.http_method && node.metadata.path) {
                  line1 = esc(node.metadata.http_method.toUpperCase()) + " " + esc(node.metadata.path);
                }
                /* no status dot */

              } else if (node.type === "doc") {
                /* Doc: title/summary in header, just "documented" status in body */
                var docSummary = node.metadata && node.metadata.summary ? node.metadata.summary : node.label;
                label = truncate(docSummary, 22);
                line1 = "documented";
                /* no status dot */

              } else if (node.type === "controller") {
                /* Controller: short name in header, file path in body */
                label = truncate(node.label, 22);
                if (node.file) line2 = node.file.split("/").slice(-1)[0];
                /* no type/status display */

              } else if (node.type === "model") {
                label = truncate(node.label, 22);
                if (node.metadata && node.metadata.table_name) line1 = node.metadata.table_name;
                else if (node.file) line2 = node.file.split("/").slice(-1)[0];

              } else {
                /* service, job, mailer, schema — default */
                label = truncate(node.label, 22);
                if (node.file) line2 = node.file.split("/").slice(-1)[0];
              }

              /* SVG icon group (16×16 box) translated to sit in header */
              var iconG = node.type === "route" ? "" :
                '<g transform="translate(8,' + Math.round((HEADER_H - 16) / 2) + ')" stroke="' + tc + '" color="' + tc + '">' +
                (TYPE_ICON_SVG[node.type] || '') + '</g>';

              return '<g class="' + cls + '" data-id="' + esc(node.id) + '" transform="translate(' + pos.x + ',' + pos.y + ')" ' +
                'style="opacity:' + opacity + '"' + filter + '>' +
                /* Outer card */
                '<rect width="' + NODE_W + '" height="' + NODE_H + '" rx="14" fill="#161b28" ' +
                  'stroke="' + tc + '" stroke-width="' + strokeW + '" stroke-opacity="' + strokeOp + '"' +
                  (dashArr ? ' stroke-dasharray="' + dashArr + '"' : '') + '/>' +
                /* Header band */
                '<path d="' + headerPath + '" fill="' + tc + '" fill-opacity="0.09"/>' +
                '<line x1="0" y1="' + HEADER_H + '" x2="' + NODE_W + '" y2="' + HEADER_H + '" stroke="' + tc + '" stroke-width="1" stroke-opacity="0.18"/>' +
                /* Icon + title in header */
                iconG +
                '<text x="' + titleX + '" y="24" fill="#f2f0ec" font-size="12" font-weight="700" font-family="-apple-system,BlinkMacSystemFont,sans-serif" letter-spacing="-0.005em">' + esc(label) + '</text>' +
                badge +
                /* Body lines */
                (line1 ? '<text x="16" y="60" fill="#a8b4c8" font-size="11" font-family="monospace" letter-spacing="0.02em">' + line1 + '</text>' : '') +
                (line2 ? '<text x="16" y="' + (line1 ? 82 : 64) + '" fill="#6b7d99" font-size="10.5" font-family="monospace">' + esc(truncate(line2, 38)) + '</text>' : '') +
              '</g>';
            }).join("");
          }

          /* ───────────────────────── AI dimming helpers ───────────────────────── */

          function aiDimNode(nodeId) {
            if (!aiMode || aiSelection.size === 0) return false;
            if (aiSelection.has(nodeId)) return false;
            return !isNeighborOfSelection(nodeId);
          }

          function aiDimEdge(edge) {
            if (!aiMode || aiSelection.size === 0) return false;
            return !aiSelection.has(edge.source) && !aiSelection.has(edge.target);
          }

          function isNeighborOfSelection(nodeId) {
            for (var i = 0; i < graph.edges.length; i++) {
              var e = graph.edges[i];
              if ((aiSelection.has(e.source) && e.target === nodeId) ||
                  (aiSelection.has(e.target) && e.source === nodeId)) return true;
            }
            return false;
          }

          /* ───────────────────────── Node interactions ───────────────────────── */

          function bindNodes() {
            canvas.querySelectorAll(".node").forEach(function(el) {
              el.addEventListener("pointerdown", startDrag);
              el.addEventListener("click", handleNodeClick);
            });
          }

          function startDrag(e) {
            if (e.shiftKey || e.button !== 0) return;
            var id = e.currentTarget.dataset.id;
            /* Collect doc nodes linked to this node (one-directional: action/controller dragging pulls its doc) */
            var draggedNode = graph.nodes.find(function(n) { return n.id === id; });
            var linkedDocs = [];
            if (draggedNode && draggedNode.type !== "doc") {
              graph.edges.forEach(function(edge) {
                if (edge.type === "documents" && edge.target === id) {
                  var p = positions[edge.source];
                  if (p) linkedDocs.push({ id: edge.source, ox: p.x, oy: p.y });
                }
              });
            }
            dragState = { id: id, cx: e.clientX, cy: e.clientY, ox: positions[id].x, oy: positions[id].y, moved: false, linkedDocs: linkedDocs };
            document.addEventListener("pointermove", onDrag);
            document.addEventListener("pointerup", endDrag, { once: true });
          }

          function onDrag(e) {
            if (!dragState) return;
            var dx = (e.clientX - dragState.cx) / zoom.scale;
            var dy = (e.clientY - dragState.cy) / zoom.scale;
            if (Math.abs(dx) + Math.abs(dy) > 3) dragState.moved = true;
            positions[dragState.id] = { x: dragState.ox + dx, y: dragState.oy + dy };
            /* Move linked doc nodes with the parent */
            dragState.linkedDocs.forEach(function(ld) {
              positions[ld.id] = { x: ld.ox + dx, y: ld.oy + dy };
            });
            render();
          }

          function endDrag() {
            document.removeEventListener("pointermove", onDrag);
            setTimeout(function() { dragState = null; }, 0);
          }

          function handleNodeClick(e) {
            if (dragState && dragState.moved) return;
            var id = e.currentTarget.dataset.id;

            if (aiMode) {
              toggleAiSelection(id);
              return;
            }

            selectedId = id;
            showNodeDetail(id);
            render();
          }

          /* ───────────────────────── AI Mode ───────────────────────── */

          function toggleAiMode() {
            aiMode = !aiMode;
            aiBtn.classList.toggle("active", aiMode);

            if (aiMode) {
              toast("AI Explain — select controllers, endpoints, or features to understand");
              showAiSelectionPanel();
            } else {
              toast("AI Explain OFF");
              aiSelection.clear();
              resetPanel();
            }
            render();
          }

          function toggleAiSelection(id) {
            if (aiSelection.has(id)) {
              aiSelection.delete(id);
            } else {
              aiSelection.add(id);
            }
            if (aiMode) showAiSelectionPanel();
            render();
          }

          function showAiSelectionPanel() {
            var categories = {};
            var candidates = graph.nodes.filter(function(n) {
              return ["controller","route","action","model","service","job","mailer","schema"].indexOf(n.type) !== -1;
            });
            candidates.forEach(function(n) {
              (categories[n.type] = categories[n.type] || []).push(n);
            });

            /* Build controller sections with actions nested */
            var controllerHtml = "";
            if (categories.controller && categories.controller.length > 0) {
              categories.controller.forEach(function(controller) {
                /* Find actions that belong to this controller */
                var actions = [];
                if (categories.action) {
                  categories.action.forEach(function(action) {
                    /* Check if action has "contains" edge from controller */
                    var belongsToController = graph.edges.some(function(e) {
                      return e.type === "contains" && e.source === controller.id && e.target === action.id;
                    });
                    if (belongsToController) {
                      actions.push(action);
                    }
                  });
                }

                /* Find routes for this controller's actions */
                var routes = [];
                if (categories.route) {
                  categories.route.forEach(function(route) {
                    var connectsToAction = actions.some(function(action) {
                      return graph.edges.some(function(e) {
                        return e.type === "routes_to" && e.source === route.id && e.target === action.id;
                      });
                    });
                    if (connectsToAction) routes.push(route);
                  });
                }

                var controllerColor = TYPE_COLORS["controller"] || "#7a8fb5";
                var controllerChecked = aiSelection.has(controller.id) ? "checked" : "";

                controllerHtml += '<div class="ai-category">' +
                  '<div class="ai-category-title" style="font-weight:700">' + esc(controller.label) + ' (controller)</div>' +
                  '<label class="ai-option" style="padding-left:12px;margin-bottom:8px">' +
                    '<input type="checkbox" data-ai-node="' + esc(controller.id) + '" ' + controllerChecked + '>' +
                    '<div class="ai-option-info">' +
                      '<span class="ai-option-label"><span class="ai-option-dot" style="background:' + controllerColor + '"></span>Select controller</span>' +
                    '</div>' +
                  '</label>';

                /* Show actions for this controller */
                if (actions.length > 0) {
                  controllerHtml += '<div style="margin-left:12px;border-left:1px solid rgba(168,180,200,.2);padding-left:8px">';
                  actions.forEach(function(action) {
                    var actionColor = TYPE_COLORS["action"] || "#f5793a";
                    var actionChecked = aiSelection.has(action.id) ? "checked" : "";
                    var actionLabel = action.metadata && action.metadata.action ? action.metadata.action : action.label;
                    var route = routes.find(function(r) {
                      return graph.edges.some(function(e) {
                        return e.type === "routes_to" && e.source === r.id && e.target === action.id;
                      });
                    });
                    var routeInfo = route && route.metadata && route.metadata.method && route.metadata.path
                      ? route.metadata.method.toUpperCase() + " " + route.metadata.path
                      : "";

                    controllerHtml += '<label class="ai-option" style="margin-bottom:4px">' +
                      '<input type="checkbox" data-ai-node="' + esc(action.id) + '" ' + actionChecked + '>' +
                      '<div class="ai-option-info">' +
                        '<span class="ai-option-label"><span class="ai-option-dot" style="background:' + actionColor + '"></span>' + esc(actionLabel) + '</span>' +
                        (routeInfo ? '<span class="ai-option-meta" style="font-size:10px;color:var(--haze)">' + esc(routeInfo) + '</span>' : '') +
                      '</div>' +
                    '</label>';
                  });
                  controllerHtml += '</div>';
                }

                controllerHtml += '</div>';
              });
            }

            /* Other categories: models, services, jobs, etc. */
            var otherOrder = ["model","service","job","mailer","schema"];
            var otherHtml = otherOrder.filter(function(t) { return categories[t]; }).map(function(type) {
              var c = TYPE_COLORS[type] || "#7a8fb5";
              var items = categories[type].map(function(n) {
                var checked = aiSelection.has(n.id) ? "checked" : "";
                return '<label class="ai-option">' +
                  '<input type="checkbox" data-ai-node="' + esc(n.id) + '" ' + checked + '>' +
                  '<div class="ai-option-info">' +
                    '<span class="ai-option-label"><span class="ai-option-dot" style="background:' + c + '"></span>' + esc(n.label) + '</span>' +
                  '</div>' +
                '</label>';
              }).join("");
              return '<div class="ai-category">' +
                '<div class="ai-category-title">' + esc(type.charAt(0).toUpperCase() + type.slice(1)) + 's (' + categories[type].length + ')</div>' +
                items +
              '</div>';
            }).join("");

            var count = aiSelection.size;
            var btnLabel = count > 0 ? "✦ Generate Explanation (" + count + " selected)" : "Select components above";
            var btnDisabled = count === 0 ? "disabled" : "";

            panel.innerHTML =
              '<div class="ai-panel-header">' +
                '<h2>✦ AI Explain</h2>' +
                '<p>Pick the controllers, endpoints, models, or services you want to understand. The AI will explain how they connect and work together — written so even a junior engineer can follow.</p>' +
              '</div>' +
              controllerHtml +
              otherHtml +
              '<div class="ai-generate-bar">' +
                '<button id="ai-generate-btn" class="ai-generate-btn" ' + btnDisabled + '>' + btnLabel + '</button>' +
              '</div>';
          }

          function generateAiInsight() {
            if (aiSelection.size === 0) {
              toast("Select at least one component first");
              return;
            }

            var btn = document.getElementById("ai-generate-btn");
            if (btn) {
              btn.disabled = true;
              btn.textContent = "✦ AI is thinking…";
              btn.classList.add("loading");
            }

            var ids = Array.from(aiSelection).join(",");
            var url = insightsUrl + "?node_ids=" + encodeURIComponent(ids);

            fetch(url)
              .then(function(r) { return r.json(); })
              .then(function(data) {
                if (data.error) throw new Error(data.error);
                showAiResults(data.insight);
              })
              .catch(function(err) {
                panel.innerHTML =
                  '<div class="panel-section"><h2>AI Explain</h2><dl>' +
                    '<dd class="panel-empty">AI insight unavailable: ' + esc(err.message) +
                    '<br><br>Run <code>rails generate docit:ai_setup</code> to configure an AI provider.</dd>' +
                  '</dl></div>';
              });
          }

          function showAiResults(insight) {
            /* Parse markdown sections from AI response */
            var sections = parseMarkdownSections(insight);
            var html = '<div class="ai-result">' +
              '<button id="ai-back-btn" class="ai-back-btn">← Back to selection</button>';

            if (sections.length > 0) {
              sections.forEach(function(sec) {
                html += '<div class="ai-result-section">' +
                  '<div class="ai-result-heading"><span class="icon">✦</span> ' + esc(sec.title) + '</div>' +
                  '<div class="ai-result-body">' + formatMarkdown(sec.body) + '</div>' +
                '</div>';
              });
            } else {
              html += '<div class="ai-result-section">' +
                '<div class="ai-result-heading"><span class="icon">✦</span> AI Explanation</div>' +
                '<div class="ai-result-body"><pre>' + esc(insight) + '</pre></div>' +
              '</div>';
            }

            html += '</div>';
            panel.innerHTML = html;
          }

          function parseMarkdownSections(md) {
            var lines = md.split("\\n");
            var sections = [];
            var current = null;

            lines.forEach(function(line) {
              var heading = line.match(/^\#{1,3}\\s+(.+)/);
              if (heading) {
                if (current) sections.push(current);
                current = { title: heading[1].trim(), body: "" };
              } else if (current) {
                current.body += line + "\\n";
              }
            });
            if (current) sections.push(current);
            return sections;
          }

          function formatMarkdown(text) {
            return text
              /* Mermaid blocks — label them clearly and show as readable code */
              .replace(/```mermaid[\\s\\S]*?```/g, function(block) {
                var code = block.replace(/```mermaid\\n?/, "").replace(/```$/, "").trim();
                return '<div style="margin:10px 0">' +
                  '<div style="font-size:10px;color:var(--haze);font-family:monospace;text-transform:uppercase;letter-spacing:.06em;margin-bottom:6px">Flow diagram</div>' +
                  '<pre style="background:rgba(26,31,46,.8);border:1px solid rgba(168,180,200,.12);border-radius:8px;padding:12px;font-size:11px;color:#a8b4c8;overflow-x:auto;line-height:1.6">' + esc(code) + '</pre>' +
                '</div>';
              })
              /* Generic code blocks */
              .replace(/```[\\s\\S]*?```/g, function(block) {
                var code = block.replace(/```\\w*\\n?/, "").replace(/```$/, "").trim();
                return '<pre style="background:rgba(26,31,46,.8);border:1px solid rgba(168,180,200,.1);border-radius:8px;padding:10px;font-size:11px;color:#a8b4c8;overflow-x:auto">' + esc(code) + '</pre>';
              })
              .replace(/\\*\\*(.+?)\\*\\*/g, '<strong style="color:#f2f0ec">$1</strong>')
              .replace(/`([^`]+)`/g, '<code style="background:rgba(26,31,46,.8);border:1px solid rgba(168,180,200,.1);padding:1px 5px;border-radius:4px;font-size:11px;color:#a8b4c8">$1</code>')
              /* Bullet lists — ember accent bar instead of purple */
              .replace(/^- (.+)$/gm, '<div style="padding:3px 0 3px 12px;border-left:2px solid rgba(245,121,58,.35);margin:4px 0;color:var(--smoke)">$1</div>')
              /* Numbered lists — ember number instead of purple */
              .replace(/^(\\d+)\\. (.+)$/gm, '<div style="display:flex;gap:8px;padding:3px 0;margin:4px 0"><span style="color:var(--ember);font-weight:600;font-size:11px;min-width:18px">$1.</span><span style="color:var(--smoke)">$2</span></div>')
              /* Inline arrows — keep readable */
              .replace(/\\u2192|\\u2194|\\->/g, '<span style="color:var(--ember)">&rarr;</span>')
              .replace(/\\n\\n/g, '<br>')
              .replace(/\\n/g, ' ');
          }

          /* ───────────────────────── Node Detail Panel ───────────────────────── */

          function showNodeDetail(id) {
            var node = graph.nodes.find(function(n) { return n.id === id; });
            if (!node) return;
            var incoming = graph.edges.filter(function(e) { return e.target === id; });
            var outgoing = graph.edges.filter(function(e) { return e.source === id; });
            var tc = TYPE_COLORS[node.type] || "#7a8fb5";
            var iconSvg = TYPE_ICON_SVG[node.type] || '<path d="M8,3 L8,13 M3,8 L13,8" stroke="currentColor" stroke-width="1.3" stroke-linecap="round"/>';
            var icon = '<svg width="20" height="20" viewBox="0 0 16 16" style="stroke:' + tc + ';color:' + tc + '">' + iconSvg + '</svg>';
            var desc = TYPE_DESCRIPTIONS[node.type] || "Application component.";

            /* Build the human-readable display label */
            var displayLabel = node.label;
            if (node.type === "action" && node.metadata && node.metadata.action) {
              displayLabel = node.metadata.action;
            }

            /* Build connection items */
            var allConnections = [];
            incoming.forEach(function(e) {
              var other = graph.nodes.find(function(n) { return n.id === e.source; });
              allConnections.push(buildConnectionItem(e, other, "incoming"));
            });
            outgoing.forEach(function(e) {
              var other = graph.nodes.find(function(n) { return n.id === e.target; });
              allConnections.push(buildConnectionItem(e, other, "outgoing"));
            });

            /* Build a quick-facts row for the header */
            var facts = [];
            if (node.type === "route" && node.metadata) {
              if (node.metadata.method) facts.push(node.metadata.method.toUpperCase());
              if (node.metadata.path) facts.push(node.metadata.path);
            } else if (node.type === "action" && node.metadata) {
              if (node.metadata.http_method) facts.push(node.metadata.http_method.toUpperCase());
              if (node.metadata.path) facts.push(node.metadata.path);
            } else if (node.status) {
              facts.push(node.status);
            }

            var factsHtml = facts.length > 0 ?
              facts.map(function(f) { return '<span class="node-fact">' + esc(f) + '</span>'; }).join(" ") : "";

            panel.innerHTML =
              '<div class="panel-section">' +
                '<div class="node-detail-header">' +
                  '<div class="node-detail-badge" style="background:' + tc + '18;color:' + tc + ';border:1px solid ' + tc + '35">' + icon + '</div>' +
                  '<div style="min-width:0">' +
                    '<div class="node-detail-title">' + esc(displayLabel) + '</div>' +
                    '<div class="node-detail-type">' + esc(node.type) + (factsHtml ? '&ensp;' + factsHtml : '') + '</div>' +
                  '</div>' +
                '</div>' +
                '<dl>' +
                  detail("What it does", '<span style="color:var(--smoke);font-size:12px;line-height:1.5">' + desc + '</span>') +
                  (node.file ? detail("File", '<code style="font-size:11px;color:#a8b4c8;word-break:break-all">' + esc(node.file) + '</code>') : '') +
                  (node.type === "controller" ? (function() {
                    var actions = graph.edges.filter(function(e) { return e.type === "contains" && e.source === node.id; })
                      .map(function(e) { return graph.nodes.find(function(n) { return n.id === e.target; }); })
                      .filter(function(n) { return n && n.type === "action"; });
                    if (actions.length === 0) return "";
                    var items = actions.map(function(a) {
                      var lbl = a.metadata && a.metadata.action ? a.metadata.action : a.label;
                      var st = a.status || "undocumented";
                      var sc = st === "documented" ? "#34c759" : "#ffb340";
                      var routes = graph.edges.filter(function(e) { return e.type === "routes_to" && e.target === a.id; })
                        .map(function(e) { return graph.nodes.find(function(n) { return n.id === e.source; }); })
                        .filter(function(n) { return n && n.type === "route"; });
                      var routeStr = routes.length > 0 ? routes.map(function(r) {
                        return (r.metadata && r.metadata.method ? r.metadata.method.toUpperCase() : "?") + " " +
                               (r.metadata && r.metadata.path ? r.metadata.path : r.label);
                      }).join(", ") : "(no route)";
                      return '<div style="margin:6px 0"><span style="color:#f2f0ec;font-weight:600">' + esc(lbl) + '</span> ' +
                        '<span style="background:' + sc + '35;color:' + sc + ';font-size:9px;padding:2px 6px;border-radius:3px;display:inline-block">' + st + '</span>' +
                        '<div style="color:#a8b4c8;font-size:11px;margin-top:2px">' + esc(routeStr) + '</div></div>';
                    }).join("");
                    return detail("Actions (" + actions.length + ")", items);
                  })() : "") +
                  detail("Connections",
                    allConnections.length > 0
                      ? allConnections.join("")
                      : '<span style="color:var(--haze);font-size:12px">No connections found</span>') +
                '</dl>' +
              '</div>';
          }

          function buildConnectionItem(edge, otherNode, direction) {
            var verb = friendlyEdgeVerb(edge.type, direction);
            var otherLabel = "Unknown";
            if (otherNode) {
              otherLabel = otherNode.type === "action" && otherNode.metadata && otherNode.metadata.action
                ? otherNode.metadata.action
                : otherNode.label;
            }
            var otherType = otherNode ? otherNode.type : "";
            var otherColor = TYPE_COLORS[otherType] || "#7a8fb5";
            var arrow = direction === "incoming" ? "←" : "→";

            return '<div class="connection-item">' +
              '<span class="connection-arrow" style="color:' + otherColor + '">' + arrow + '</span>' +
              '<div class="connection-info">' +
                '<span class="connection-verb">' + verb + '</span>' +
                '<span class="connection-label">' + esc(truncate(otherLabel, 32)) + '</span>' +
                (otherType ? '<span class="connection-type">(' + esc(otherType) + ')</span>' : '') +
              '</div>' +
              '<button type="button" data-edge="' + esc(edge.id) + '" class="connection-remove" title="Remove">\u00d7</button>' +
            '</div>';
          }

          function friendlyEdgeVerb(edgeType, direction) {
            var verbs = {
              routes_to:   { incoming: "Receives request from",  outgoing: "Routes to" },
              contains:    { incoming: "Belongs to",             outgoing: "Contains" },
              documents:   { incoming: "Documented by",          outgoing: "Documents" },
              association: { incoming: "Associated with",        outgoing: "Associated with" },
              uses_model:  { incoming: "Used by",                outgoing: "Uses model" },
              calls:       { incoming: "Called by",              outgoing: "Calls" },
              manual:      { incoming: "Linked from",            outgoing: "Linked to" }
            };
            var entry = verbs[edgeType];
            if (entry) return entry[direction] || edgeType;
            return edgeType;
          }

          function resetPanel() {
            panel.innerHTML =
              '<div class="panel-welcome">' +
                '<div class="welcome-icon">◆</div>' +
                '<h2>System Architecture</h2>' +
                '<p>Click a node to inspect it, or use AI Explain to understand how components work together.</p>' +
                '<div class="welcome-tips">' +
                  '<div class="tip"><span class="tip-icon">👆</span><span>Click a node to inspect it</span></div>' +
                  '<div class="tip"><span class="tip-icon">✋</span><span>Drag nodes to rearrange the layout</span></div>' +
                  '<div class="tip"><span class="tip-icon">🔍</span><span>Scroll to zoom · Shift-drag to pan</span></div>' +
                  '<div class="tip"><span class="tip-icon">✦</span><span>Use <strong>AI Explain</strong> to understand any part</span></div>' +
                '</div>' +
              '</div>';
          }

          /* ───────────────────────── PNG Export (fixed) ───────────────────────── */

          function exportPng() {
            var svg = document.getElementById("system-svg");
            if (!svg) { toast("No diagram to export"); return; }

            var current = visibleGraph();
            var bounds = graphBounds(current.nodes);
            var pad = 60;

            /* Clone and adjust the SVG for standalone rendering */
            var clone = svg.cloneNode(true);
            var w = bounds.w + pad * 2;
            var h = bounds.h + pad * 2;
            clone.setAttribute("width", w);
            clone.setAttribute("height", h);
            clone.setAttribute("viewBox", (bounds.x - pad) + " " + (bounds.y - pad) + " " + w + " " + h);
            clone.setAttribute("xmlns", "http://www.w3.org/2000/svg");

            /* Remove the zoom transform so the viewBox framing is used instead */
            var zoomGroup = clone.querySelector("#zoom-group");
            if (zoomGroup) zoomGroup.setAttribute("transform", "");

            /* Add a dark background rect as the first child */
            var bg = document.createElementNS("http://www.w3.org/2000/svg", "rect");
            bg.setAttribute("x", bounds.x - pad);
            bg.setAttribute("y", bounds.y - pad);
            bg.setAttribute("width", w);
            bg.setAttribute("height", h);
            bg.setAttribute("fill", "#0f1117");
            clone.insertBefore(bg, clone.firstChild);

            /* Serialize to XML string */
            var xml = new XMLSerializer().serializeToString(clone);

            /* Ensure proper XML namespace */
            if (xml.indexOf("xmlns") === -1) {
              xml = xml.replace("<svg", '<svg xmlns="http://www.w3.org/2000/svg"');
            }

            var blob = new Blob([xml], { type: "image/svg+xml;charset=utf-8" });
            var url = URL.createObjectURL(blob);
            var img = new Image();
            var scale = 2;

            img.onload = function() {
              var canvasEl = document.createElement("canvas");
              canvasEl.width = w * scale;
              canvasEl.height = h * scale;
              var ctx = canvasEl.getContext("2d");
              ctx.scale(scale, scale);
              ctx.fillStyle = "#0f1117";
              ctx.fillRect(0, 0, w, h);
              ctx.drawImage(img, 0, 0, w, h);
              URL.revokeObjectURL(url);

              canvasEl.toBlob(function(pngBlob) {
                var link = document.createElement("a");
                link.download = "docit-system-architecture.png";
                link.href = URL.createObjectURL(pngBlob);
                link.click();
                setTimeout(function() { URL.revokeObjectURL(link.href); }, 100);
                toast("PNG exported!");
              }, "image/png");
            };

            img.onerror = function() {
              URL.revokeObjectURL(url);
              /* Fallback: download SVG instead */
              var svgLink = document.createElement("a");
              svgLink.download = "docit-system-architecture.svg";
              svgLink.href = URL.createObjectURL(blob);
              svgLink.click();
              toast("Exported as SVG (PNG rendering failed)");
            };

            img.src = url;
          }

          /* ───────────────────────── Legend ───────────────────────── */

          function buildLegend() {
            var types = uniqueSorted(graph.nodes.map(function(n) { return n.type; }));
            var edgeTypes = uniqueSorted(graph.edges.map(function(e) { return e.type; }));

            legendContent.innerHTML =
              '<div class="legend-section">' +
                '<div class="legend-heading">Node Types</div>' +
                types.map(function(t) {
                  return '<div class="legend-item"><span class="legend-dot" style="background:' + (TYPE_COLORS[t] || "#7a8fb5") + '"></span><span>' + esc(t) + '</span></div>';
                }).join("") +
              '</div>' +
              '<div class="legend-section">' +
                '<div class="legend-heading">Edge Types</div>' +
                edgeTypes.map(function(t) {
                  return '<div class="legend-item"><span class="legend-line" style="background:' + (EDGE_COLORS[t] || "#7a8fb5") + '"></span><span>' + esc(t) + '</span></div>';
                }).join("") +
              '</div>' +
              '<div class="legend-section">' +
                '<div class="legend-heading">Status</div>' +
                '<div class="legend-item"><span class="legend-dot" style="background:#34c759"></span><span>Documented</span></div>' +
                '<div class="legend-item"><span class="legend-dot" style="background:#ffb340"></span><span>Undocumented</span></div>' +
                '<div class="legend-item"><span class="legend-dot" style="background:#7a8fb5"></span><span>Unknown</span></div>' +
              '</div>';
          }

          function toggleLegendPanel() {
            legendEl.classList.toggle("collapsed");
            legendToggle.textContent = legendEl.classList.contains("collapsed") ? "Legend ▸" : "Legend ▾";
          }

          /* ───────────────────────── Utilities ───────────────────────── */

          function detail(label, value) {
            return '<dt>' + esc(label) + '</dt><dd>' + value + '</dd>';
          }

          function toast(msg) {
            toastEl.textContent = msg;
            toastEl.classList.add("visible");
            setTimeout(function() { toastEl.classList.remove("visible"); }, 2200);
          }

          function truncate(s, n) {
            return s.length > n ? s.slice(0, n - 1) + "…" : s;
          }

          function esc(s) {
            var map = { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" };
            return String(s).replace(/[&<>"']/g, function(c) { return map[c]; });
          }

          function uniqueSorted(arr) {
            return Array.from(new Set(arr)).sort();
          }

          })();
        JS
      end
    end
  end
end

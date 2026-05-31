# frozen_string_literal: true

module Docit
  module UI
    module SystemScript
      def self.javascript(graph_url:, insights_url:)
        <<~JS
          (function() {
          "use strict";

          /* ───────────────────────── Configuration ───────────────────────── */

          const graphUrl  = #{json_escape(JSON.generate(graph_url))};
          const insightsUrl = #{json_escape(JSON.generate(insights_url))};

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
          let dragState    = null;
          let panState     = null;
          let zoom         = { scale: 1, tx: 0, ty: 0 };
          /* Set of node ids directly adjacent to the selected node, for focus
             mode. Rebuilt only when the selection changes — not per render. */
          let focusNeighbors = null;

          /* ───────────────────────── DOM refs ───────────────────────── */

          const $  = (id) => document.getElementById(id);
          const canvas     = $("canvas");
          const canvasWrap = $("canvas-wrap");
          const panel      = $("panel");
          const searchEl   = $("search");
          const sectionFilterDiagram = $("diagram-section-filter");
          const statsEl    = $("stats");
          const exportBtn  = $('export-png');
          const toastEl    = $("toast");
          const zoomInBtn  = $("zoom-in");
          const zoomOutBtn = $("zoom-out");
          const zoomFitBtn = $("zoom-fit");
          const zoomLabel  = $("zoom-level");
          const legendEl   = $("legend");
          const legendToggle  = $("legend-toggle");
          const legendContent = $("legend-content");
          const themeToggle   = $("theme-toggle");

          /* ───────────────────────── Theme ───────────────────────── */

          const SUN_ICON = '<svg width="15" height="15" viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round"><circle cx="8" cy="8" r="3"/><path d="M8 1v1.6M8 13.4V15M2.4 2.4l1.1 1.1M12.5 12.5l1.1 1.1M1 8h1.6M13.4 8H15M2.4 13.6l1.1-1.1M12.5 3.5l1.1-1.1"/></svg>';
          const MOON_ICON = '<svg width="15" height="15" viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round"><path d="M13.5 9.3A5.5 5.5 0 0 1 6.7 2.5a5.5 5.5 0 1 0 6.8 6.8z"/></svg>';

          /* Shared line-icon glyphs used across panels (replaces emoji). */
          function lineIcon(paths, size) {
            var s = size || 14;
            return '<svg width="' + s + '" height="' + s + '" viewBox="0 0 16 16" fill="none" stroke="currentColor" ' +
              'stroke-width="1.3" stroke-linecap="round" stroke-linejoin="round">' + paths + '</svg>';
          }
          const ICON_SPARKLE = '<path d="M8 1.5l1.6 4.3 4.4 1.6-4.4 1.6L8 13.4 6.4 9 2 7.4l4.4-1.6L8 1.5z"/>';
          const ICON_CLICK   = '<path d="M6 7V3.5a1.2 1.2 0 0 1 2.4 0V7m0-1.2a1.2 1.2 0 0 1 2.4 0V7m0-.6a1.2 1.2 0 0 1 2.4 0v3.2a4 4 0 0 1-4 4H9a4 4 0 0 1-3.3-1.7L3.5 8.8a1.2 1.2 0 0 1 2-1.3L6 8"/>';
          const ICON_DRAG    = '<path d="M3 8h10M8 3l5 5-5 5M3 8l5-5M3 8l5 5"/>';
          const ICON_SEARCH  = '<circle cx="7" cy="7" r="4.5"/><path d="M10.5 10.5l3 3"/>';

          function currentTheme() {
            return document.documentElement.getAttribute("data-theme") === "dark" ? "dark" : "light";
          }

          /* The button shows the theme you'll switch TO, the common affordance. */
          function syncThemeButton() {
            if (!themeToggle) return;
            themeToggle.innerHTML = currentTheme() === "dark" ? SUN_ICON : MOON_ICON;
          }

          function toggleTheme() {
            var next = currentTheme() === "dark" ? "light" : "dark";
            if (next === "dark") document.documentElement.setAttribute("data-theme", "dark");
            else document.documentElement.removeAttribute("data-theme");
            try { localStorage.setItem("docit-theme", next); } catch (e) {}
            syncThemeButton();
            /* Re-render so SVG diagram picks up theme-driven fills. */
            if (currentView === "diagram") render();
            else renderStripeDocs();
          }

          syncThemeButton();
          if (themeToggle) themeToggle.addEventListener("click", toggleTheme);

          /* "/" focuses node search (diagram view); Esc clears focus/selection. */
          document.addEventListener("keydown", function(e) {
            var typing = /^(INPUT|SELECT|TEXTAREA)$/.test(document.activeElement && document.activeElement.tagName);
            if (e.key === "/" && !typing && currentView === "diagram") {
              e.preventDefault();
              searchEl.focus();
              searchEl.select();
            } else if (e.key === "Escape" && selectedId !== null) {
              selectedId = null;
              focusNeighbors = null;
              resetPanel();
              render();
            }
          });

          /* ───────────────────────── Init ───────────────────────── */

          fetch(graphUrl)
            .then(function(r) { return r.json(); })
            .then(function(data) {
              graph = data;
              buildFilters();
              buildLegend();
              positions = layoutNodes(graph.nodes);
              render();
              resetPanel();
              setTimeout(zoomToFit, 60);
            })
            .catch(function(err) {
              canvas.innerHTML = '<div class="panel-empty">Unable to load system graph: ' + esc(err.message) + '</div>';
            });

          /* ───────────────────────── Events ───────────────────────── */

          const sectionFilter = $("section-filter");
          const diagramFilters = $("diagram-filters");
          const docsFilters    = $("docs-filters");

          searchEl.addEventListener("input", function() {
            if (currentView === "diagram") render();
            else renderStripeDocs();
          });
          if (sectionFilterDiagram) {
            sectionFilterDiagram.addEventListener("change", function() {
              zoomToFit();   /* reframe to the chosen section */
            });
          }
          if (sectionFilter) sectionFilter.addEventListener("change", renderStripeDocs);
          exportBtn.addEventListener("click", exportPng);
          zoomInBtn.addEventListener("click", function() { applyZoom(1.3); });
          zoomOutBtn.addEventListener("click", function() { applyZoom(0.77); });
          zoomFitBtn.addEventListener("click", zoomToFit);
          legendToggle.addEventListener("click", toggleLegendPanel);

          const viewDiagramBtn = $("view-diagram");
          const viewListBtn    = $("view-list");
          const canvasWrapEl   = $("canvas-wrap");
          const stripeDocsWrapEl = $("stripe-docs-wrap");
          let currentView = "diagram";

          viewDiagramBtn.addEventListener("click", function() { switchViewMode("diagram"); });
          viewListBtn.addEventListener("click", function() { switchViewMode("list"); });

          function switchViewMode(mode) {
            currentView = mode;
            var isDiagram = mode === "diagram";

            /* Each view shows only the filters that make sense for it:
               free-text search + type on the diagram, resource section on docs. */
            if (diagramFilters) diagramFilters.style.display = isDiagram ? "flex" : "none";
            if (docsFilters)    docsFilters.style.display    = isDiagram ? "none" : "flex";

            if (isDiagram) {
              viewListBtn.classList.remove("active");
              viewDiagramBtn.classList.add("active");
              stripeDocsWrapEl.style.display = "none";
              canvasWrapEl.style.display = "block";
              render();
            } else {
              viewDiagramBtn.classList.remove("active");
              viewListBtn.classList.add("active");
              canvasWrapEl.style.display = "none";
              stripeDocsWrapEl.style.display = "grid";
              buildSectionFilter();
              renderStripeDocs();
            }
          }

          /* Populate the resource-section dropdown from controllers, once.
             Each option is a resource (e.g. "Users"), value is the controller id. */
          function buildSectionFilter() {
            if (!sectionFilter || sectionFilter.dataset.built === "1") return;
            var controllers = graph.nodes
              .filter(function(n) { return n.type === "controller"; })
              .map(function(n) { return { id: n.id, name: resourceName(n.label).plural }; })
              .sort(function(a, b) { return a.name.localeCompare(b.name); });
            controllers.forEach(function(c) {
              var opt = document.createElement("option");
              opt.value = c.id;
              opt.textContent = c.name;
              sectionFilter.appendChild(opt);
            });
            sectionFilter.dataset.built = "1";
          }

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
            /* A click on empty canvas (no drag) clears focus/selection. */
            if (panState && !panState.moved && selectedId !== null) {
              selectedId = null;
              focusNeighbors = null;
              resetPanel();
              render();
            }
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
            }
          });

          /* ───────────────────────── Filters & Layout ───────────────────────── */

          /* Populate the diagram's section filter from controllers — one option
             per resource (Users, Orders…), value is the controller id. Same
             source as the docs section filter, so the two views agree. */
          function buildFilters() {
            if (!sectionFilterDiagram) return;
            graph.nodes
              .filter(function(n) { return n.type === "controller"; })
              .map(function(n) { return { id: n.id, name: resourceName(n.label).plural }; })
              .sort(function(a, b) { return a.name.localeCompare(b.name); })
              .forEach(function(c) {
                var opt = document.createElement("option");
                opt.value = c.id;
                opt.textContent = c.name;
                sectionFilterDiagram.appendChild(opt);
              });
          }

          /* All node ids that make up a section's end-to-end story:
             the controller, its actions, each action's routes & docs, and the
             models/services/jobs/mailers those actions use. */
          function sectionNodeIds(controllerId) {
            var ids = new Set([controllerId]);
            var actionIds = sectionActionIds(controllerId);
            actionIds.forEach(function(actionId) {
              ids.add(actionId);
              graph.edges.forEach(function(e) {
                /* incoming: route -> action, doc -> action */
                if (e.target === actionId && (e.type === "routes_to" || e.type === "documents")) {
                  ids.add(e.source);
                }
                /* outgoing: action -> model/service/job/mailer */
                if (e.source === actionId) ids.add(e.target);
              });
            });
            return ids;
          }

          function visibleGraph() {
            var q = searchEl.value.toLowerCase();
            var section = sectionFilterDiagram ? sectionFilterDiagram.value : "";
            var sectionIds = section ? sectionNodeIds(section) : null;

            var nodes = graph.nodes.filter(function(n) {
              return (!sectionIds || sectionIds.has(n.id)) &&
                     (!q || n.label.toLowerCase().indexOf(q) !== -1);
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
              var opacity = focusDimEdge(edge) ? 0.07 : 0.45;
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
              var dimmed = focusDimNode(node.id);
              var tc = TYPE_COLORS[node.type] || "#7a8fb5";
              var sc = status === "documented" ? "#34c759" : status === "undocumented" ? "#ffb340" : "#7a8fb5";

              var cls = "node " + esc(node.type);
              if (isSel) cls += " selected";

              var opacity = dimmed ? 0.14 : 1;
              var strokeW = isSel ? 2 : 1.2;
              var strokeOp = isSel ? 1 : 0.32;
              var dashArr = "";
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
                '<rect width="' + NODE_W + '" height="' + NODE_H + '" rx="14" fill="var(--bg-solid)" ' +
                  'stroke="' + tc + '" stroke-width="' + strokeW + '" stroke-opacity="' + strokeOp + '"' +
                  (dashArr ? ' stroke-dasharray="' + dashArr + '"' : '') + '/>' +
                /* Header band */
                '<path d="' + headerPath + '" fill="' + tc + '" fill-opacity="0.09"/>' +
                '<line x1="0" y1="' + HEADER_H + '" x2="' + NODE_W + '" y2="' + HEADER_H + '" stroke="' + tc + '" stroke-width="1" stroke-opacity="0.18"/>' +
                /* Icon + title in header */
                iconG +
                '<text x="' + titleX + '" y="24" fill="var(--text)" font-size="12" font-weight="700" font-family="-apple-system,BlinkMacSystemFont,sans-serif" letter-spacing="-0.005em">' + esc(label) + '</text>' +
                badge +
                /* Body lines */
                (line1 ? '<text x="16" y="60" fill="var(--smoke)" font-size="11" font-family="monospace" letter-spacing="0.02em">' + line1 + '</text>' : '') +
                (line2 ? '<text x="16" y="' + (line1 ? 82 : 64) + '" fill="var(--haze)" font-size="10.5" font-family="monospace">' + esc(truncate(line2, 38)) + '</text>' : '') +
              '</g>';
            }).join("");
          }

          /* ───────────────────────── Focus mode ─────────────────────────
             When a node is selected, spotlight it and its direct neighbors;
             everything else fades back. Helps trace one component's
             connections in a busy graph. */

          function focusActive() { return selectedId !== null && focusNeighbors !== null; }

          function rebuildFocusNeighbors() {
            if (selectedId === null) { focusNeighbors = null; return; }
            var set = new Set([selectedId]);
            graph.edges.forEach(function(e) {
              if (e.source === selectedId) set.add(e.target);
              if (e.target === selectedId) set.add(e.source);
            });
            focusNeighbors = set;
          }

          function focusDimNode(nodeId) {
            return focusActive() && !focusNeighbors.has(nodeId);
          }

          function focusDimEdge(edge) {
            return focusActive() && edge.source !== selectedId && edge.target !== selectedId;
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

            selectedId = id;
            rebuildFocusNeighbors();
            showNodeDetail(id);
            render();
          }

          function formatMarkdown(text) {
            return text
              /* Mermaid blocks — label them clearly and show as readable code */
              .replace(/```mermaid[\\s\\S]*?```/g, function(block) {
                var code = block.replace(/```mermaid\\n?/, "").replace(/```$/, "").trim();
                return '<div style="margin:10px 0">' +
                  '<div style="font-size:10px;color:var(--haze);font-family:monospace;text-transform:uppercase;letter-spacing:.06em;margin-bottom:6px">Flow diagram</div>' +
                  '<pre style="background:var(--bg-code);border:1px solid var(--border);border-radius:8px;padding:12px;font-size:11px;color:var(--smoke);overflow-x:auto;line-height:1.6">' + esc(code) + '</pre>' +
                '</div>';
              })
              /* Generic code blocks */
              .replace(/```[\\s\\S]*?```/g, function(block) {
                var code = block.replace(/```\\w*\\n?/, "").replace(/```$/, "").trim();
                return '<pre style="background:var(--bg-code);border:1px solid var(--border);border-radius:8px;padding:10px;font-size:11px;color:var(--smoke);overflow-x:auto">' + esc(code) + '</pre>';
              })
              .replace(/\\*\\*(.+?)\\*\\*/g, '<strong style="color:var(--text)">$1</strong>')
              .replace(/`([^`]+)`/g, '<code style="background:var(--bg-code);border:1px solid var(--border);padding:1px 5px;border-radius:4px;font-size:11px;color:var(--smoke)">$1</code>')
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
                  (node.file ? detail("File", '<code style="font-size:11px;color:var(--smoke);word-break:break-all">' + esc(node.file) + '</code>') : '') +
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
                      return '<div style="margin:6px 0"><span style="color:var(--text);font-weight:600">' + esc(lbl) + '</span> ' +
                        '<span style="background:' + sc + '35;color:' + sc + ';font-size:9px;padding:2px 6px;border-radius:3px;display:inline-block">' + st + '</span>' +
                        '<div style="color:var(--smoke);font-size:11px;margin-top:2px">' + esc(routeStr) + '</div></div>';
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

          /* ───────────────────────── Endpoint titles ─────────────────────────
             A "proper definition" for an endpoint heading. Order of preference:
               1. the documented summary (human-written, always wins)
               2. a REST-conventional title derived from the action + resource
                  (index -> "List Posts", show -> "Get a Post", ...)
               3. a humanized version of the raw action name as a last resort. */

          function humanize(str) {
            return String(str)
              .replace(/[_-]+/g, " ")
              .replace(/([a-z])([A-Z])/g, "$1 $2")
              .replace(/\\b\\w/g, function(c) { return c.toUpperCase(); })
              .trim();
          }

          /* "UsersController" / "Admin::OrdersController" -> { plural:"Orders", singular:"Order" } */
          function resourceName(controllerLabel) {
            var base = String(controllerLabel || "")
              .split(/::|\\//).pop()
              .replace(/Controller$/, "");
            var plural = humanize(base);
            var singular = plural
              .replace(/ies$/, "y")
              .replace(/ses$/, "s")
              .replace(/s$/, "");
            return { plural: plural || "Resource", singular: singular || "Resource" };
          }

          function endpointTitle(action, controllerLabel, docSummary) {
            if (docSummary && docSummary.trim()) return docSummary.trim();

            var name = (action.metadata && action.metadata.action ? action.metadata.action : action.label) || "";
            var res = resourceName(controllerLabel);
            var templates = {
              index:   "List " + res.plural,
              show:    "Get a " + res.singular,
              "new":   "New " + res.singular + " form",
              create:  "Create a " + res.singular,
              edit:    "Edit " + res.singular + " form",
              update:  "Update a " + res.singular,
              destroy: "Delete a " + res.singular
            };
            return templates[name] || humanize(name) + " " + res.singular;
          }

          function resetPanel() {
            panel.innerHTML =
              '<div class="panel-welcome">' +
                '<div class="welcome-icon">' +
                  '<svg width="22" height="22" viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.3" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="2" width="5" height="5" rx="1.2"/><rect x="9" y="2" width="5" height="5" rx="1.2"/><rect x="2" y="9" width="5" height="5" rx="1.2"/><rect x="9" y="9" width="5" height="5" rx="1.2"/><path d="M7 4.5h2M4.5 7v2M11.5 7v2"/></svg>' +
                '</div>' +
                '<h2>System Architecture</h2>' +
                '<p>Click a node to inspect how it connects to the rest of the system.</p>' +
                '<div class="welcome-tips">' +
                  '<div class="tip"><span class="tip-icon">' + lineIcon(ICON_CLICK) + '</span><span>Click a node to inspect it</span></div>' +
                  '<div class="tip"><span class="tip-icon">' + lineIcon(ICON_DRAG) + '</span><span>Drag nodes to rearrange the layout</span></div>' +
                  '<div class="tip"><span class="tip-icon">' + lineIcon(ICON_SEARCH) + '</span><span>Scroll to zoom · Shift-drag to pan</span></div>' +
                '</div>' +
              '</div>';
          }

          /* ───────────────────────── PNG Export ───────────────────────── */

          function exportPng() {
            var svg = document.getElementById("system-svg");
            if (!svg) { toast("No diagram to export"); return; }

            var current = visibleGraph();
            var bounds = graphBounds(current.nodes);
            var pad = 60;

            /* Export background must match the active theme, not a fixed color. */
            var exportBg = currentTheme() === "dark" ? "#0f1117" : "#ffffff";

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
            bg.setAttribute("fill", exportBg);
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
              ctx.fillStyle = exportBg;
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

          /* ───────────────────────── Stripe Docs logical view ───────────────────────── */

          window.inspectNode = function(nodeId) {
            selectedId = nodeId;
            showNodeDetail(nodeId);
            render();
            if (window.innerWidth <= 980) {
              panel.scrollIntoView({ behavior: "smooth" });
            }
          };

          /* ───────────────────────── Docs detail panel ───────────────────────── */

          const detailPanel = $("stripe-detail");
          const detailBody  = $("stripe-detail-body");
          const detailClose = $("stripe-detail-close");

          /* Action node-ids belonging to a controller (the section's endpoints). */
          function sectionActionIds(controllerId) {
            return graph.edges
              .filter(function(e) { return e.type === "contains" && e.source === controllerId; })
              .map(function(e) { return e.target; })
              .filter(function(id) {
                var n = graph.nodes.find(function(x) { return x.id === id; });
                return n && n.type === "action";
              });
          }

          /* The doc node documenting an action, if any. */
          function docForAction(actionId) {
            var docEdge = graph.edges.find(function(e) {
              return e.type === "documents" && e.target === actionId;
            });
            if (!docEdge) return null;
            return graph.nodes.find(function(n) { return n.id === docEdge.source; });
          }

          /* The route (method + path) for an action, if any. */
          function routeForAction(actionId) {
            var routeEdge = graph.edges.find(function(e) {
              return e.type === "routes_to" && e.target === actionId;
            });
            if (!routeEdge) return null;
            return graph.nodes.find(function(n) { return n.id === routeEdge.source; });
          }

          function openDetailPanel(html) {
            if (!detailPanel || !detailBody) return;
            detailBody.innerHTML = html;
            detailPanel.scrollTop = 0;
            detailPanel.classList.add("open"); /* only matters in drawer mode */
          }

          function closeDetailPanel() {
            if (detailPanel) detailPanel.classList.remove("open");
          }

          if (detailClose) detailClose.addEventListener("click", closeDetailPanel);

          /* Render an endpoint's request/response reference into the panel.
             All fields come from the doc node — nothing is invented. */
          function showEndpointDetail(actionId) {
            var action = graph.nodes.find(function(n) { return n.id === actionId; });
            if (!action) return;

            /* Highlight the matching card. */
            var contentEl = $("stripe-content");
            if (contentEl) {
              contentEl.querySelectorAll(".stripe-endpoint-card.detail-active").forEach(function(c) {
                c.classList.remove("detail-active");
              });
              var card = document.getElementById("action-" + actionId.replace(/:/g, "-"));
              if (card) card.classList.add("detail-active");
            }

            var controllerEdge = graph.edges.find(function(e) { return e.type === "contains" && e.target === actionId; });
            var controllerLabel = controllerEdge
              ? (graph.nodes.find(function(n) { return n.id === controllerEdge.source; }) || {}).label
              : "";

            var route = routeForAction(actionId);
            var method = route && route.metadata ? (route.metadata.method || "GET").toUpperCase() : "";
            var path = route && route.metadata ? (route.metadata.path || "") : "";
            var doc = docForAction(actionId);
            var meta = (doc && doc.metadata) || {};
            var actionName = action.metadata && action.metadata.action ? action.metadata.action : action.label;
            var definition = endpointTitle(action, controllerLabel, doc ? doc.label : "");
            var methodColor = METHOD_COLORS[method] || "var(--haze)";

            var html = '<div class="detail-kicker">Endpoint</div>';
            html += '<h2 class="detail-title">' + esc(definition) + '</h2>';
            if (method && path) {
              html += '<div class="detail-endpoint-line">' +
                '<span class="verb" style="color:' + methodColor + '">' + method + '</span>' +
                '<span class="path">' + esc(path) + '</span></div>';
            }
            if (meta.description) {
              html += '<p class="detail-desc">' + esc(meta.description) + '</p>';
            }

            html += renderParams(meta.parameters);
            html += renderRequestBody(meta.request_body);
            html += renderResponses(meta.responses);

            if (!doc) {
              html += '<div class="detail-section"><div class="detail-error">' +
                'This endpoint has no documentation yet. Add a Docit doc-block to ' +
                '<span class="mono">' + esc(actionName) + '</span> to see its parameters, request body, and responses here.' +
                '</div></div>';
            }

            openDetailPanel(html);
          }

          function renderParams(params) {
            if (!params || params.length === 0) return "";
            var rows = params.map(function(p) {
              return '<div class="detail-param">' +
                '<div class="detail-param-head">' +
                  '<span class="detail-param-name">' + esc(p.name) + '</span>' +
                  (p.type ? '<span class="detail-param-type">' + esc(p.type) + '</span>' : '') +
                  (p.location ? '<span class="detail-chip loc">' + esc(p.location) + '</span>' : '') +
                  (p.required ? '<span class="detail-chip req">required</span>' : '') +
                '</div>' +
                (p.description ? '<div class="detail-param-desc">' + esc(p.description) + '</div>' : '') +
              '</div>';
            }).join("");
            return '<div class="detail-section"><div class="detail-section-title">Parameters</div>' + rows + '</div>';
          }

          function renderRequestBody(body) {
            if (!body) return "";
            var props = body.properties;
            var shape;
            if (props && typeof props === "object") {
              shape = JSON.stringify(props, null, 2);
            } else {
              shape = "(no schema described)";
            }
            var ct = body.content_type ? esc(body.content_type) : "application/json";
            return '<div class="detail-section">' +
              '<div class="detail-section-title">Request body' + (body.required ? ' · required' : '') + '</div>' +
              '<div class="detail-param-desc" style="margin-bottom:8px">Content-Type: <span class="mono">' + ct + '</span></div>' +
              '<pre class="detail-code">' + esc(shape) + '</pre></div>';
          }

          function renderResponses(responses) {
            if (!responses || responses.length === 0) return "";
            var rows = responses.map(function(r) {
              var status = String(r.status || "");
              var sc = status.charAt(0) === "2" ? "var(--success)"
                     : status.charAt(0) === "4" ? "var(--danger)"
                     : status.charAt(0) === "5" ? "var(--warning)" : "var(--haze)";
              var body = "";
              if (r.examples && Object.keys(r.examples).length > 0) {
                body = '<pre class="detail-code">' + esc(JSON.stringify(r.examples, null, 2)) + '</pre>';
              } else if (r.properties && Object.keys(r.properties).length > 0) {
                body = '<pre class="detail-code">' + esc(JSON.stringify(r.properties, null, 2)) + '</pre>';
              }
              return '<div class="detail-response">' +
                '<div class="detail-response-head">' +
                  '<span class="detail-chip" style="background:' + sc + '1a;color:' + sc + '">' + esc(status) + '</span>' +
                  (r.description ? '<span class="detail-response-desc">' + esc(r.description) + '</span>' : '') +
                '</div>' + body +
              '</div>';
            }).join("");
            return '<div class="detail-section"><div class="detail-section-title">Responses</div>' + rows + '</div>';
          }

          /* Render the AI section explanation into the panel. The
             undocumented-endpoint warning is handled by the caller. */
          function showSectionExplain(controllerId) {
            var ids = sectionActionIds(controllerId);
            var controller = graph.nodes.find(function(n) { return n.id === controllerId; });
            var sectionName = controller ? resourceName(controller.label).plural : "Section";

            if (ids.length === 0) {
              openDetailPanel('<div class="detail-kicker">Section</div><h2 class="detail-title">' + esc(sectionName) +
                '</h2><div class="detail-error">No endpoints to explain in this section.</div>');
              return;
            }

            openDetailPanel('<div class="detail-kicker">Section</div><h2 class="detail-title">' + esc(sectionName) + '</h2>' +
              '<div class="detail-ai-head">' + lineIcon(ICON_SPARKLE) + ' How this section works</div>' +
              '<div class="detail-loading">Generating explanation…</div>');

            var url = insightsUrl + "?mode=section&node_ids=" + encodeURIComponent(ids.join(","));
            fetch(url)
              .then(function(r) { return r.json(); })
              .then(function(data) {
                if (data.error) throw new Error(data.error);
                openDetailPanel('<div class="detail-kicker">Section</div><h2 class="detail-title">' + esc(sectionName) + '</h2>' +
                  '<div class="detail-ai-head">' + lineIcon(ICON_SPARKLE) + ' How this section works</div>' +
                  '<div class="detail-ai-body">' + formatMarkdown(data.insight) + '</div>');
              })
              .catch(function(err) {
                openDetailPanel('<div class="detail-kicker">Section</div><h2 class="detail-title">' + esc(sectionName) + '</h2>' +
                  '<div class="detail-error">Explanation unavailable: ' + esc(err.message) +
                  '<br>Run <span class="mono">rails generate docit:ai_setup</span> to configure an AI provider.</div>');
              });
          }

          /* One-time delegation on the docs content: section Explain + endpoint clicks. */
          (function bindDocsInteractions() {
            var content = $("stripe-content");
            if (!content) return;
            content.addEventListener("click", function(e) {
              var sectionBtn = e.target.closest(".stripe-explain-btn");
              if (sectionBtn) {
                /* Gate: warn before spending tokens on a thinly-documented section. */
                if (sectionBtn.dataset.fulldoc !== "1") {
                  var ok = window.confirm(
                    sectionBtn.dataset.undoc + " endpoint(s) in this section are undocumented.\\n\\n" +
                    "The explanation may be weak and will use more tokens. For the best result, " +
                    "document these endpoints first.\\n\\nGenerate anyway?");
                  if (!ok) return;
                }
                showSectionExplain(sectionBtn.dataset.section);
                return;
              }
              /* Relation cards have their own behavior (jump to the diagram). */
              if (e.target.closest(".stripe-relation-card")) return;
              /* A click on an endpoint card (or its View details button) opens
                 that endpoint's request/response detail in the panel. */
              var endpointBtn = e.target.closest(".stripe-endpoint-explain");
              if (endpointBtn) { showEndpointDetail(endpointBtn.dataset.action); return; }
              var card = e.target.closest(".stripe-endpoint-card");
              if (card && card.dataset.action) { showEndpointDetail(card.dataset.action); return; }
            });
          })();

          function renderStripeDocs() {
            const sidebar = $("stripe-sidebar");
            const content = $("stripe-content");
            if (!sidebar || !content) return;

            /* Docs view filters by resource section, not free-text. An empty
               value means "All sections"; otherwise it's a controller id. */
            const selectedSection = sectionFilter ? sectionFilter.value : "";
            let controllers = graph.nodes.filter(function(n) {
              return n.type === "controller" && (!selectedSection || n.id === selectedSection);
            });

            controllers = controllers.sort(function(a, b) { return a.label.localeCompare(b.label); });

            let sidebarHtml = "";
            let contentHtml = "";

            if (controllers.length === 0) {
              content.innerHTML = '<div class="panel-empty">No endpoints found for this section.</div>';
              sidebar.innerHTML = "";
              return;
            }

            controllers.forEach(function(controller) {
              let actions = graph.edges
                .filter(function(e) { return e.type === "contains" && e.source === controller.id; })
                .map(function(e) { return graph.nodes.find(function(n) { return n.id === e.target; }); })
                .filter(function(n) { return n && n.type === "action"; });

              actions = actions.sort(function(a, b) { return a.label.localeCompare(b.label); });
              if (actions.length === 0) return;

              const controllerAnchor = "controller-" + controller.id.replace(/:/g, "-");
              
              sidebarHtml += '<div class="stripe-sidebar-group">';
              sidebarHtml += '<div class="stripe-sidebar-heading">' + esc(controller.label.replace("Controller", "")) + '</div>';

              var res = resourceName(controller.label);

              /* Documentation coverage drives both the badge and the AI gate:
                 a fully-documented section gives the model real input; a thin
                 one yields a weak explanation and still costs tokens. */
              var documentedCount = actions.filter(function(a) { return a.status === "documented"; }).length;
              var totalCount = actions.length;
              var fullyDocumented = documentedCount === totalCount;
              var coverageColor = fullyDocumented ? "var(--success)" : "var(--warning)";

              contentHtml += '<section class="stripe-controller-block" id="' + controllerAnchor + '">';
              contentHtml += '  <div class="stripe-controller-header">';
              contentHtml += '    <div>';
              contentHtml += '      <div class="stripe-controller-kicker">Resource</div>';
              contentHtml += '      <h2 class="stripe-controller-title">' + esc(res.plural) + '</h2>';
              contentHtml += '    </div>';
              contentHtml += '    <div class="stripe-controller-aside">';
              contentHtml += '      <span class="stripe-coverage" style="color:' + coverageColor + ';border-color:' + coverageColor + '40;background:' + coverageColor + '12">' +
                documentedCount + '/' + totalCount + ' documented</span>';
              contentHtml += '      <button class="stripe-explain-btn" type="button" ' +
                'data-section="' + esc(controller.id) + '" data-fulldoc="' + (fullyDocumented ? "1" : "0") +
                '" data-undoc="' + (totalCount - documentedCount) + '">Explain section</button>';
              contentHtml += '    </div>';
              contentHtml += '  </div>';
              contentHtml += '  <p class="stripe-controller-sub">' + actions.length + ' endpoint' + (actions.length === 1 ? '' : 's') +
                (controller.file ? ' &middot; <span class="mono">' + esc(controller.file) + '</span>' : '') + '</p>';

              actions.forEach(function(action) {
                const actionAnchor = "action-" + action.id.replace(/:/g, "-");
                const actionLabel = action.metadata && action.metadata.action ? action.metadata.action : action.label;

                const routes = graph.edges
                  .filter(function(e) { return e.type === "routes_to" && e.target === action.id; })
                  .map(function(e) { return graph.nodes.find(function(n) { return n.id === e.source; }); })
                  .filter(function(n) { return n && n.type === "route"; });

                const route = routes[0];
                const method = route && route.metadata ? (route.metadata.method || "GET").toUpperCase() : "";
                const path = route && route.metadata ? (route.metadata.path || "") : "";

                const docs = graph.edges
                  .filter(function(e) { return e.type === "documents" && e.target === action.id; })
                  .map(function(e) { return graph.nodes.find(function(n) { return n.id === e.source; }); })
                  .filter(function(n) { return n && n.type === "doc"; });

                const doc = docs[0];
                const summary = doc && doc.label ? doc.label : (action.metadata && action.metadata.summary ? action.metadata.summary : "");
                const status = action.status || "undocumented";
                const isDocumented = status === "documented";

                /* The heading is a proper definition; the raw action name becomes a kicker. */
                const definition = endpointTitle(action, controller.label, summary);
                const methodColor = METHOD_COLORS[method] || "var(--haze)";
                const statusColor = isDocumented ? "var(--success)" : "var(--warning)";

                /* Sidebar: definition as the link text, method as a trailing chip.
                   Carries data-action so a click also opens the detail panel. */
                sidebarHtml += '<a class="stripe-sidebar-item" href="#' + actionAnchor + '" data-action="' + esc(action.id) + '">';
                sidebarHtml += '  <span class="stripe-sidebar-label">' + esc(definition) + '</span>';
                if (method) {
                  sidebarHtml += '  <span class="stripe-sidebar-badge" style="background:' + methodColor + '20;color:' + methodColor + '">' + method + '</span>';
                }
                sidebarHtml += '</a>';

                contentHtml += '<article class="stripe-endpoint-card" id="' + actionAnchor + '" data-action="' + esc(action.id) + '">';
                contentHtml += '  <div class="stripe-endpoint-header">';
                contentHtml += '    <div class="stripe-endpoint-title-wrap">';
                contentHtml += '      <div class="stripe-endpoint-kicker"><span class="mono">' + esc(actionLabel) + '</span>';
                contentHtml += '        <span class="action-doc-badge" style="background:' + statusColor + '15;color:' + statusColor + ';border-color:' + statusColor + '30">' + status + '</span>';
                contentHtml += '      </div>';
                contentHtml += '      <h3 class="stripe-endpoint-title">' + esc(definition) + '</h3>';
                contentHtml += '    </div>';
                contentHtml += '    <button class="stripe-endpoint-explain system-btn" type="button" data-action="' + esc(action.id) + '">View details</button>';
                contentHtml += '  </div>';

                if (method && path) {
                  contentHtml += '  <div class="stripe-endpoint-meta">';
                  contentHtml += '    <span class="stripe-endpoint-verb" style="color:' + methodColor + '">' + method + '</span>';
                  contentHtml += '    <span class="stripe-endpoint-path">' + esc(path) + '</span>';
                  contentHtml += '  </div>';
                }

                if (summary && summary !== definition) {
                  contentHtml += '  <div class="stripe-endpoint-desc">' + esc(summary) + '</div>';
                } else if (!summary) {
                  contentHtml += '  <div class="stripe-endpoint-desc stripe-endpoint-desc--empty">No description provided yet. Add a Docit doc-block to this action to document it.</div>';
                }

                const relations = graph.edges
                  .filter(function(e) { return e.source === action.id || e.source === controller.id; })
                  .map(function(e) { return { edge: e, node: graph.nodes.find(function(n) { return n.id === e.target; }) }; })
                  .filter(function(r) { return r.node && ["model", "service", "job", "mailer"].indexOf(r.node.type) !== -1; });

                if (relations.length > 0) {
                  contentHtml += '  <div class="stripe-relations-title">Interacts with</div>';
                  contentHtml += '  <div class="stripe-relations-grid">';
                  relations.forEach(function(rel) {
                    const typeColor = TYPE_COLORS[rel.node.type] || "var(--haze)";
                    const typeIcon = TYPE_ICON_SVG[rel.node.type] || "";
                    contentHtml += '    <div class="stripe-relation-card" onclick="window.inspectNode(\\\'' + rel.node.id + '\\\')">';
                    contentHtml += '      <div class="stripe-relation-icon" style="background:' + typeColor + '15;color:' + typeColor + ';border:1px solid ' + typeColor + '30">';
                    contentHtml += '        <svg width="13" height="13" viewBox="0 0 16 16" style="color:' + typeColor + '">' + typeIcon + '</svg>';
                    contentHtml += '      </div>';
                    contentHtml += '      <div class="stripe-relation-text">';
                    contentHtml += '        <span class="stripe-relation-name">' + esc(rel.node.label) + '</span>';
                    contentHtml += '        <span class="stripe-relation-type">' + esc(rel.node.type) + '</span>';
                    contentHtml += '      </div>';
                    contentHtml += '    </div>';
                  });
                  contentHtml += '  </div>';
                }

                contentHtml += '</article>';
              });

              contentHtml += '</section>';
              sidebarHtml += '</div>';
            });

            sidebar.innerHTML = sidebarHtml;
            content.innerHTML = contentHtml;

            const sidebarLinks = sidebar.querySelectorAll(".stripe-sidebar-item");
            sidebarLinks.forEach(function(link) {
              link.addEventListener("click", function(e) {
                e.preventDefault();
                const targetId = this.getAttribute("href").substring(1);
                const targetEl = document.getElementById(targetId);
                if (targetEl) {
                  targetEl.scrollIntoView({ behavior: "smooth", block: "start" });
                  sidebarLinks.forEach(function(l) { l.classList.remove("active"); });
                  this.classList.add("active");
                }
                /* Also open the endpoint's detail in the right panel. */
                if (this.dataset.action) showEndpointDetail(this.dataset.action);
              });
            });

            content.onscroll = function() {
              const scrollPos = content.scrollTop + 60;
              controllers.forEach(function(controller) {
                const actions = graph.edges
                  .filter(function(e) { return e.type === "contains" && e.source === controller.id; })
                  .map(function(e) { return graph.nodes.find(function(n) { return n.id === e.target; }); })
                  .filter(function(n) { return n && n.type === "action"; });

                actions.forEach(function(action) {
                  const actionAnchor = "action-" + action.id.replace(/:/g, "-");
                  const el = document.getElementById(actionAnchor);
                  if (el && el.offsetTop <= scrollPos && (el.offsetTop + el.offsetHeight) > scrollPos) {
                    sidebarLinks.forEach(function(l) {
                      if (l.getAttribute("href") === "#" + actionAnchor) {
                        l.classList.add("active");
                      } else {
                        l.classList.remove("active");
                      }
                    });
                  }
                });
              });
            };
          }

          })();
        JS
      end

      def self.json_escape(json_string)
        json_string.to_s.gsub(/[&<>'\u2028\u2029]/, {
          '&' => '\u0026',
          '<' => '\u003c',
          '>' => '\u003e',
          "'" => '\u0027',
          "\u2028" => '\u2028',
          "\u2029" => '\u2029'
        })
      end
    end
  end
end

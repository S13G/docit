# frozen_string_literal: true

module Docit
  module UI
    class BaseRenderer
      attr_reader :spec_url, :system_url, :system_insights_url, :title, :nav_paths

      def initialize(spec_url:, system_url: nil, system_insights_url: nil, nav_paths: {})
        @spec_url = spec_url
        @system_url = system_url
        @system_insights_url = system_insights_url
        @nav_paths = nav_paths
        @title = ERB::Util.html_escape(Docit.configuration.title)
      end

      def render
        raise NotImplementedError, "#{self.class}#render must be implemented"
      end

      private

      def nav_bar(active:)
        swagger_active = active == :swagger
        scalar_active = active == :scalar
        system_active = active == :system

        <<~HTML
          <style>
            /* Theme-aware nav. Falls back to the original dark values when the
               page has no theme tokens (e.g. Swagger/Scalar renderers). */
            .docit-nav {
              display: flex; align-items: center; gap: 8px;
              padding: 6px 16px;
              background: var(--bg-glass, #111827);
              color: var(--text, #ffffff);
              border-bottom: 1px solid var(--border, transparent);
              backdrop-filter: blur(12px) saturate(150%);
              font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
              font-size: 13px; position: sticky; top: 0; z-index: 9999;
            }
            .docit-nav-link {
              color: var(--haze, rgba(255,255,255,0.7)); text-decoration: none;
              padding: 4px 12px; border-radius: 6px;
              transition: all 150ms;
              font-family: inherit;
              font-size: inherit;
            }
            .docit-nav-link:hover {
              color: var(--text, #ffffff); background: var(--bg-option-hover, rgba(255,255,255,0.15));
            }
            .docit-nav-link.active {
              color: var(--ember, #ffffff); background: var(--bg-option-hover, rgba(255,255,255,0.15)); font-weight: 600;
            }
          </style>
          <nav class="docit-nav">
            <span style="font-weight: 600; margin-right: auto;">#{title}</span>
            <a href="#{ERB::Util.html_escape(nav_paths[:swagger])}" class="docit-nav-link #{'active' if swagger_active}">Swagger</a>
            <a href="#{ERB::Util.html_escape(nav_paths[:scalar])}" class="docit-nav-link #{'active' if scalar_active}">Scalar</a>
            <a href="#{ERB::Util.html_escape(nav_paths[:system])}" class="docit-nav-link #{'active' if system_active}">System</a>
          </nav>
        HTML
      end

      def spec_url_json
        json_escape(JSON.generate(spec_url))
      end

      def system_url_json
        json_escape(JSON.generate(system_url))
      end

      def system_insights_url_json
        json_escape(JSON.generate(system_insights_url))
      end

      def json_escape(json_string)
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

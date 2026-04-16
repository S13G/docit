# frozen_string_literal: true

module Docit
  module UI
    class BaseRenderer
      attr_reader :spec_url, :title, :nav_paths

      def initialize(spec_url:, nav_paths: {})
        @spec_url = spec_url
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

        <<~HTML
          <nav style="
            display: flex; align-items: center; gap: 8px;
            padding: 6px 16px;
            background: #1a1a2e; color: #fff;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            font-size: 13px; position: sticky; top: 0; z-index: 9999;
          ">
            <span style="font-weight: 600; margin-right: auto;">#{title}</span>
            #{nav_link("Swagger", nav_paths[:swagger], active: swagger_active)}
            #{nav_link("Scalar", nav_paths[:scalar], active: scalar_active)}
          </nav>
        HTML
      end

      def nav_link(label, path, active:)
        escaped_path = ERB::Util.html_escape(path)
        style = if active
                  "color: #fff; text-decoration: none; padding: 4px 12px; border-radius: 4px; background: rgba(255,255,255,0.15); font-weight: 500;"
                else
                  "color: rgba(255,255,255,0.7); text-decoration: none; padding: 4px 12px; border-radius: 4px;"
                end

        %(<a href="#{escaped_path}" style="#{style}">#{label}</a>)
      end

      def spec_url_json
        JSON.generate(spec_url)
      end
    end
  end
end

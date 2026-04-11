# frozen_string_literal: true

require "json"

module Docit
  class UiController < ActionController::Base
    SWAGGER_UI_VERSION = "5.32.2"

    def index
      render html: swagger_ui_html.html_safe, layout: false
    end

    def spec
      RouteInspector.eager_load_controllers!
      render json: SchemaGenerator.generate
    end

    private

    def swagger_ui_html
      spec_url = "#{request.base_url}#{Docit::Engine.routes.url_helpers.spec_path}"
      spec_url_json = JSON.generate(spec_url)
      escaped_title = ERB::Util.html_escape(Docit.configuration.title)

      <<~HTML
        <!DOCTYPE html>
        <html lang="en">
        <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>#{escaped_title}</title>
          <link rel="stylesheet" href="https://unpkg.com/swagger-ui-dist@#{SWAGGER_UI_VERSION}/swagger-ui.css" />
          <style>
            html { box-sizing: border-box; overflow-y: scroll; }
            *, *:before, *:after { box-sizing: inherit; }
            body { margin: 0; background: #fafafa; }
          </style>
        </head>
        <body>
          <div id="swagger-ui"></div>
          <script src="https://unpkg.com/swagger-ui-dist@#{SWAGGER_UI_VERSION}/swagger-ui-bundle.js"></script>
          <script>
            SwaggerUIBundle({
              url: #{spec_url_json},
              dom_id: '#swagger-ui',
              presets: [
                SwaggerUIBundle.presets.apis,
                SwaggerUIBundle.SwaggerUIStandalonePreset
              ],
              layout: "BaseLayout",
              deepLinking: true,
              showExtensions: true,
              showCommonExtensions: true,
              requestInterceptor: function(req) {
                var url = new URL(req.url);
                url.protocol = window.location.protocol;
                url.host = window.location.host;
                req.url = url.toString();
                return req;
              }
            })
          </script>
        </body>
        </html>
      HTML
    end
  end
end

# frozen_string_literal: true

module Docket
  class UiController < ActionController::Base
    def index
      render html: swagger_ui_html.html_safe, layout: false
    end

    def spec
      render json: SchemaGenerator.generate
    end

    private

    def swagger_ui_html
      spec_url = "#{request.base_url}#{Docket::Engine.routes.url_helpers.spec_path}"

      <<~HTML
        <!DOCTYPE html>
        <html lang="en">
        <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>#{Docket.configuration.title}</title>
          <link rel="stylesheet" href="https://unpkg.com/swagger-ui-dist@5/swagger-ui.css" />
          <style>
            html { box-sizing: border-box; overflow-y: scroll; }
            *, *:before, *:after { box-sizing: inherit; }
            body { margin: 0; background: #fafafa; }
          </style>
        </head>
        <body>
          <div id="swagger-ui"></div>
          <script src="https://unpkg.com/swagger-ui-dist@5/swagger-ui-bundle.js"></script>
          <script>
            SwaggerUIBundle({
              url: "#{spec_url}",
              dom_id: '#swagger-ui',
              presets: [
                SwaggerUIBundle.presets.apis,
                SwaggerUIBundle.SwaggerUIStandalonePreset
              ],
              layout: "BaseLayout",
              deepLinking: true,
              showExtensions: true,
              showCommonExtensions: true
            })
          </script>
        </body>
        </html>
      HTML
    end
  end
end

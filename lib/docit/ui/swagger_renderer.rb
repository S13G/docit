# frozen_string_literal: true

module Docit
  module UI
    class SwaggerRenderer < BaseRenderer
      VERSION = "5.32.2"

      def render
        <<~HTML
          <!DOCTYPE html>
          <html lang="en">
          <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>#{title}</title>
            <link rel="stylesheet" href="https://unpkg.com/swagger-ui-dist@#{VERSION}/swagger-ui.css" />
            <style>
              html { box-sizing: border-box; overflow-y: scroll; }
              *, *:before, *:after { box-sizing: inherit; }
              body { margin: 0; background: #fafafa; }
            </style>
          </head>
          <body>
            #{nav_bar(active: :swagger)}
            <div id="swagger-ui"></div>
            <script src="https://unpkg.com/swagger-ui-dist@#{VERSION}/swagger-ui-bundle.js"></script>
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
end

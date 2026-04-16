# frozen_string_literal: true

module Docit
  module UI
    class ScalarRenderer < BaseRenderer
      def render
        <<~HTML
          <!DOCTYPE html>
          <html lang="en">
          <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>#{title}</title>
            <style>
              body { margin: 0; }
            </style>
          </head>
          <body>
            #{nav_bar(active: :scalar)}
            <script id="api-reference"></script>
            <script>
              document.getElementById('api-reference').dataset.configuration = JSON.stringify({
                spec: { url: #{spec_url_json} },
                theme: "elysiajs",
                showSidebar: true,
                hideDownloadButton: false,
                hideModels: false,
                searchHotKey: "k"
              })
            </script>
            <script src="https://cdn.jsdelivr.net/npm/@scalar/api-reference"></script>
          </body>
          </html>
        HTML
      end
    end
  end
end

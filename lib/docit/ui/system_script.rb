# frozen_string_literal: true

require "json"

module Docit
  module UI
    # JavaScript for the System Map UI. The script lives in assets/system.js so
    # it can be edited and linted as a real file; it is read once and inlined by
    # SystemRenderer. The only per-render value (the graph endpoint URL) is passed
    # through `window.DocitSystem`, set by `config_script` before the script runs.
    module SystemScript
      JAVASCRIPT = File.read(File.join(__dir__, "assets", "system.js")).freeze

      def self.javascript
        JAVASCRIPT
      end

      # Inline config the script reads at startup. Kept tiny and JSON-escaped so a
      # crafted URL cannot break out of the <script> context.
      def self.config_script(graph_url:)
        "window.DocitSystem = { graphUrl: #{json_escape(JSON.generate(graph_url))} };"
      end

      def self.json_escape(json_string)
        json_string.to_s.gsub(/[&<>'\u2028\u2029]/, {
                                "&" => '\u0026',
                                "<" => '\u003c',
                                ">" => '\u003e',
                                "'" => '\u0027',
                                "\u2028" => '\u2028',
                                "\u2029" => '\u2029'
                              })
      end
    end
  end
end

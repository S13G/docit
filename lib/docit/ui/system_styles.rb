# frozen_string_literal: true

module Docit
  module UI
    # Stylesheet for the System Map UI. The CSS lives in assets/system.css so it
    # can be edited and linted as a real stylesheet; it is read once and inlined
    # into the page by SystemRenderer.
    module SystemStyles
      CSS = File.read(File.join(__dir__, "assets", "system.css")).freeze

      def self.css
        CSS
      end
    end
  end
end

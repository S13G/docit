# frozen_string_literal: true

module Docit
  module Generators
    class InstallGenerator < Rails::Generators::Base
      desc "Creates a Docit initializer and mounts the engine in routes"
      source_root File.expand_path("templates", __dir__)

      def copy_initializer
        template "initializer.rb", "config/initializers/docit.rb"
      end

      def mount_engine
        route 'mount Docit::Engine => "/api-docs"'
      end

      def print_instructions
        say ""
        say "Docit installed successfully!", :green
        say ""
        say "Next steps:"
        say "  1. Edit config/initializers/docit.rb to customize your API docs"
        say "  2. Add swagger_doc blocks to your controller actions"
        say "  3. Visit /api-docs to see your Swagger UI"
        say ""
      end
    end
  end
end

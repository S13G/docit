# frozen_string_literal: true

require "json"

module Docit
  class UiController < ActionController::Base
    def index
      render_ui(Docit.configuration.default_ui)
    end

    def swagger
      render_ui(:swagger)
    end

    def scalar
      render_ui(:scalar)
    end

    def spec
      RouteInspector.eager_load_controllers!
      render json: SchemaGenerator.generate
    end

    private

    RENDERERS = {
      swagger: UI::SwaggerRenderer,
      scalar: UI::ScalarRenderer
    }.freeze

    def render_ui(ui_name)
      renderer = RENDERERS.fetch(ui_name).new(spec_url: spec_url, nav_paths: nav_paths)
      render html: renderer.render.html_safe, layout: false
    end

    def spec_url
      "#{request.base_url}#{Docit::Engine.routes.url_helpers.spec_path}"
    end

    def nav_paths
      helpers = Docit::Engine.routes.url_helpers
      { swagger: helpers.swagger_path, scalar: helpers.scalar_path }
    end
  end
end

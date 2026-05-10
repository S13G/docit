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

    def system
      render_ui(:system)
    end

    def system_spec
      return render(json: { error: "System graph disabled" }, status: :not_found) unless Docit.configuration.system_graph_enabled

      RouteInspector.eager_load_controllers!
      render json: SystemGraph::Generator.generate
    end

    def system_insights
      graph = system_graph
      insight = Ai::SystemInsightGenerator.new(graph: graph, selected_node_ids: selected_node_ids).generate
      render json: { insight: insight }
    rescue Docit::Error => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def spec
      RouteInspector.eager_load_controllers!
      render json: SchemaGenerator.generate
    end

    private

    RENDERERS = {
      swagger: UI::SwaggerRenderer,
      scalar: UI::ScalarRenderer,
      system: UI::SystemRenderer
    }.freeze

    def render_ui(ui_name)
      renderer = RENDERERS.fetch(ui_name).new(
        spec_url: spec_url,
        system_url: system_url,
        system_insights_url: system_insights_url,
        nav_paths: nav_paths
      )
      render html: renderer.render.html_safe, layout: false
    end

    def system_graph
      RouteInspector.eager_load_controllers!
      SystemGraph::Generator.generate
    end

    def selected_node_ids
      params.fetch(:node_ids, "").to_s.split(",").reject(&:empty?)
    end

    def spec_url
      "#{request.base_url}#{Docit::Engine.routes.url_helpers.spec_path}"
    end

    def system_url
      "#{request.base_url}#{Docit::Engine.routes.url_helpers.system_spec_path}"
    end

    def system_insights_url
      "#{request.base_url}#{Docit::Engine.routes.url_helpers.system_insights_path}"
    end

    def nav_paths
      helpers = Docit::Engine.routes.url_helpers
      { swagger: helpers.swagger_path, scalar: helpers.scalar_path, system: helpers.system_path }
    end
  end
end

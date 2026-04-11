# frozen_string_literal: true

module Docit
  module Ai
    class GapDetector
      SKIP_PREFIXES = %w[docit/ rails/ active_storage/ action_mailbox/].freeze

      def initialize(controller_filter: nil)
        @controller_filter = controller_filter
      end

      def detect
        RouteInspector.eager_load_controllers!

        all_routes.each_with_object([]) do |route_info, gaps|
          controller = route_info[:controller]
          action = route_info[:action]

          next if Registry.find(controller: controller, action: action)

          routes = RouteInspector.routes_for(controller, action)
          next if routes.empty?

          gaps << {
            controller: controller,
            action: action,
            path: routes.first[:path],
            method: routes.first[:method]
          }
        end
      end

      private

      def all_routes
        Rails.application.routes.routes.filter_map do |route|
          controller_path = route.defaults[:controller]
          action = route.defaults[:action]
          next if controller_path.nil? || action.nil?
          next if skip_route?(controller_path)

          controller_class = "#{controller_path}_controller".camelize
          next if @controller_filter && controller_class != @controller_filter

          { controller: controller_class, action: action }
        end.uniq
      end

      def skip_route?(controller_path)
        SKIP_PREFIXES.any? { |prefix| controller_path.start_with?(prefix) }
      end
    end
  end
end

# frozen_string_literal: true

module Docit
  # Introspects Rails routes to map controller actions to HTTP paths and methods.
  class RouteInspector
    VALID_METHODS = %w[get post put patch delete].freeze

    # Eagerly loads controller classes so swagger_doc/use_docs macros run before spec generation.
    def self.eager_load_controllers!
      return if defined?(Rails).nil? || Rails.application.routes.nil?

      controller_paths = Rails.application.routes.routes.filter_map do |route|
        route.defaults[:controller]
      end.uniq

      controller_paths.each do |path|
        class_name = "#{path}_controller".camelize
        class_name.constantize
      rescue NameError
        # Skip controllers that can't be loaded (e.g., Rails internal routes)
      end
    end

    def self.routes_for(controller_name, action_name)
      return [] if defined?(Rails).nil? || Rails.application.routes.nil?

      action = action_name.to_s

      # Convert Api::V1::AuthController to api/v1/auth
      controller_path = controller_name.underscore.delete_suffix("_controller").gsub("::", "/")

      Rails.application.routes.routes.filter_map do |route|
        next if route.defaults[:controller] != controller_path
        next if route.defaults[:action] != action

        verb = extract_verb(route)
        next if VALID_METHODS.exclude?(verb)

        { path: normalize_path(route.path.spec.to_s), method: verb }
      end
    end

    def self.extract_verb(route)
      verb = route.verb
      verb = verb.source if verb.is_a?(Regexp)
      verb.to_s.downcase.gsub(/[^a-z]/, "")
    end

    private_class_method :extract_verb

    def self.normalize_path(path)
      path
        .gsub("(.:format)", "")
        .gsub(/\(\.?:(\w+)\)/, '{\1}')
        .gsub(/:(\w+)/, '{\1}')
    end

    private_class_method :normalize_path
  end
end

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
        controller_class = class_name.safe_constantize

        reload_controller(path) if controller_class && !registered_controller?(controller_class.name)

        class_name.constantize
      rescue LoadError, NameError
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

    def self.registered_controller?(controller_name)
      Registry.operations.any? { |operation| operation.controller == controller_name }
    end

    private_class_method :registered_controller?

    def self.reload_controller(path)
      controller_file = Rails.root.join("app/controllers/#{path}_controller.rb")
      load controller_file if controller_file.exist?
    end

    private_class_method :reload_controller

    def self.normalize_path(path)
      path
        .gsub("(.:format)", "")
        .gsub(/\(\.?:(\w+)\)/, '{\1}')
        .gsub(/:(\w+)/, '{\1}')
    end

    private_class_method :normalize_path
  end
end

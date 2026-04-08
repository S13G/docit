# frozen_string_literal: true

require "docket"

module Docket
  class Engine < ::Rails::Engine
    isolate_namespace Docket

    initializer "docket.include_dsl" do
      ActiveSupport.on_load(:action_controller_api) do
        include Docket::DSL
      end

      ActiveSupport.on_load(:action_controller_base) do
        include Docket::DSL
      end
    end
  end
end

# frozen_string_literal: true

require "docit"

module Docit
  class Engine < ::Rails::Engine
    isolate_namespace Docit

    initializer "docit.include_dsl" do
      ActiveSupport.on_load(:action_controller_api) do
        include Docit::DSL
      end

      ActiveSupport.on_load(:action_controller_base) do
        include Docit::DSL
      end
    end
  end
end

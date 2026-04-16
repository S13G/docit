# frozen_string_literal: true

Docit::Engine.routes.draw do
  root to: "ui#index"
  get "swagger", to: "ui#swagger"
  get "scalar", to: "ui#scalar"
  get "spec", to: "ui#spec", defaults: { format: :json }
end

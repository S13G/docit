# frozen_string_literal: true

Docit::Engine.routes.draw do
  root to: "ui#index"
  get "swagger", to: "ui#swagger"
  get "scalar", to: "ui#scalar"
  get "system.json", to: "ui#system_spec", defaults: { format: :json }, as: :system_spec
  get "system", to: "ui#system", as: :system
  get "spec", to: "ui#spec", defaults: { format: :json }
end

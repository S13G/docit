# frozen_string_literal: true

Docit::Engine.routes.draw do
  root to: "ui#index"
  get "spec", to: "ui#spec", defaults: { format: :json }
end

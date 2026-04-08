# frozen_string_literal: true

Docket::Engine.routes.draw do
  root to: "ui#index"
  get "spec", to: "ui#spec", defaults: { format: :json }
end

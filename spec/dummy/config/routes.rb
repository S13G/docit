Rails.application.routes.draw do
  mount Docit::Engine => "/api-docs"

  namespace :api do
    namespace :v1 do
      post "auth/register", to: "auth#register"
      post "auth/login", to: "auth#login"
      get "users", to: "users#index"
      get "users/:id", to: "users#show"
    end
  end
end

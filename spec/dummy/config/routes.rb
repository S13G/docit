Rails.application.routes.draw do
  mount Docit::Engine => "/api-docs"
  namespace :api do
    namespace :v1 do
      post "auth/register", to: "auth#register"
      post "auth/login", to: "auth#login"
      get "users", to: "users#index"
      get "users/:id", to: "users#show"

      resources :products, only: %i[index show create update destroy]

      resources :orders, only: %i[index show create] do
        member do
          post :cancel
        end
      end
    end
  end
end

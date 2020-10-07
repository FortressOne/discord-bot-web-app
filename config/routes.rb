Rails.application.routes.draw do
  root 'dashboard_items#index'

  resources :players, only: [:index]
  resources :matches, only: [:index]
  resources :dashboard_items, only: [:index]

  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      resources :matches, only: [:create]
    end
  end
end

Rails.application.routes.draw do
  get 'discord_channels/show'
  root 'dashboard_items#index'

  resources :players, only: [:index]
  resources :matches, only: [:index]
  resources :discord_channels, only: [:show]
  resources :dashboard_items, only: [:index]

  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      resources :matches, only: [:create]
      resources :fair_teams, only: [:new]
    end
  end
end

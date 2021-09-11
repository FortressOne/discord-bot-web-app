Rails.application.routes.draw do
  namespace 'results' do
    root to: 'discord_channels#index'
    resources :discord_channels, only: [:show]

    namespace :api, defaults: { format: :json } do
      namespace :v1 do
        resources :matches, only: [:create]
        resources :fair_teams, only: [:new]
      end
    end
  end

  root to: 'home#index'
end

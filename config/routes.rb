Rails.application.routes.draw do
  devise_for :players, controllers: { omniauth_callbacks: 'players/omniauth_callbacks' }
  devise_scope :player do
    delete 'sign_out', :to => 'devise/sessions#destroy', :as => :destroy_player_session
  end

  resources :players, only: [:index, :show]

  root to: 'home#index'
  get 'live_player/show'
  get 'code-of-conduct', to: "static_pages#code_of_conduct"

  namespace 'results' do
    root to: 'discord_channels#index'
    resources :discord_channels, only: [:show]

    namespace :api, defaults: { format: :json } do
      namespace :v1 do
        resources :matches, only: [:create]
        post "matches/:id", to: "matches#update"
        resources :fair_teams, only: [:new]
      end
    end
  end
end

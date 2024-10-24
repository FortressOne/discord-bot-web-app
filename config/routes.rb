Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  devise_for :players, controllers: { omniauth_callbacks: 'players/omniauth_callbacks' }
  devise_scope :player do
    delete 'sign_out', :to => 'devise/sessions#destroy', :as => :destroy_player_session
  end

  root to: 'home#index'
  get 'live_player/show'
  get 'code-of-conduct', to: 'static_pages#code_of_conduct'

  resources :players, only: [:index, :show, :update] do
    get 'rotate_token', on: :member
  end

  resources :matches, only: [:index, :show]
  resources :discord_channels, only: [:index, :show]

  namespace 'results' do
    namespace :api, defaults: { format: :json } do
      namespace :v1 do
        resources :map_suggestions, only: [:index, :create]
        post 'map_suggestions/vote', to: 'map_suggestions#vote'
        resources :matches, only: [:create]
        post 'fo_login', to: 'fo_logins#create'
        post 'matches/:id', to: 'matches#update'
        resources :fair_teams, only: [:new]
      end

      namespace :v2 do
        post 'fo_login', to: 'fo_logins#create'
      end
    end
  end
end

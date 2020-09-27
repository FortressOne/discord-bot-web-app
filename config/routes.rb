Rails.application.routes.draw do
  root 'ratings#index'

  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      resources :matches, only: [:create]
    end
  end
end

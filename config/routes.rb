Rails.application.routes.draw do
  # Health check for Railway readiness probes.
  get "/up", to: proc { [200, {}, ["OK"]] }

  namespace :api do
    namespace :v1 do
      post "auth/register", to: "auth#register"
      post "auth/login", to: "auth#login"
      get "auth/me", to: "auth#me"
      patch "auth/me", to: "auth#update_me"
      patch "auth/password", to: "auth#change_password"

      resources :products
      resources :customers
      resources :suppliers
      resources :transactions, only: [:index, :show, :create]
      resources :purchases, only: [:index, :show, :create, :update, :destroy] do
        member do
          patch :lunasi
        end
      end
      resources :financial_records
      resources :payment_methods, only: [:index, :create, :update, :destroy]

      resources :cash_sessions, only: [:index, :create] do
        collection do
          get :active
        end
        member do
          patch :close
        end
      end

      get "reports/summary", to: "reports#summary"
    end
  end
end
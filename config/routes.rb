Rails.application.routes.draw do
  # Health check — dipakai Railway untuk cek apakah container sudah siap.
  get "/up", to: proc { [200, {}, ["OK"]] }

  namespace :api do
    namespace :v1 do
      post "auth/register", to: "auth#register"
      post "auth/login", to: "auth#login"
      get "auth/me", to: "auth#me"

      resources :products
      resources :customers
      resources :transactions, only: [:index, :show, :create]
      resources :financial_records

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

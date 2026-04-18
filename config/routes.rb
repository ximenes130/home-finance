Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  root "dashboard#show"

  resources :accounts do
    resource :activation, only: [ :create, :destroy ], controller: "accounts/activations"
  end

  resources :categories, except: :show

  resources :budgets

  resources :transactions, except: :show
  resources :transfers, only: [ :new, :create ]

  resources :csv_imports, only: [ :index, :new, :create, :show ] do
    resource :column_mapping, only: [ :show, :update ], controller: "csv_imports/column_mappings"
    resource :confirmation, only: [ :show, :create ], controller: "csv_imports/confirmations"
  end

  resources :csv_exports, only: [ :new, :create ]
end

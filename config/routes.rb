Rails.application.routes.draw do
  devise_for :users

  resources :pdf_imports, only: [:new, :create, :index]

  # Health check route
  get "up" => "rails/health#show", as: :rails_health_check

  post 'database_resets', to: 'database_resets#create', as: :database_reset

  # Root route
  root "pdf_imports#new"
end

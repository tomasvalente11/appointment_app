Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  get "locale/:locale", to: "locales#update", as: :locale

  root "nutritionists#landing"
  get "find", to: "nutritionists#index", as: :find_nutritionists

  resources :nutritionists, only: [] do
    resource :availability, only: [:show, :update], controller: "nutritionist_availability"
    get :requests, on: :member
  end

  namespace :api do
    resources :nutritionists, only: [] do
      resources :appointment_requests, only: [:index], shallow: true
      get :available_slots, on: :member
      get :available_dates, on: :member
    end
    resources :appointment_requests, only: [:create, :update]
  end
end

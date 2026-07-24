Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "candidate_onboardings#upload"

  get "login", to: "sessions#new"
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy"

  resources :candidate_profiles, only: [:index, :show, :edit, :update, :destroy]
  resource :candidate_onboarding, only: [:show, :update] do
    member do
      get :upload
      post :upload_cv
      get :status
      get :edit_profile
      get :onboarded
      get :profile
    end
  end
end

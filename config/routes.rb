Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :admin do
    get "login", to: "sessions#new"
    post "login", to: "sessions#create"
    delete "logout", to: "sessions#destroy"

    resources :candidate_profiles, only: [:index, :show]
    root "candidate_profiles#index"
  end

  root "candidate_onboardings#upload"

  resource :candidate_onboarding, only: [:show, :update] do
    member do
      get :upload
      post :upload_cv
      get :status
      get :status_frame
      get :edit_profile
      get :onboarded
    end
  end
end
Bottlenose::Application.routes.draw do
  # Using devise for user auth.
  devise_for :users

  # Student routes.
  #################

  root to: "main#home"
  get "about" => "main#about"

  resources :courses, only: [:index, :show] do
    resources :reg_requests, only: [:new, :create]
    resources :assignments, only: :show do
      resources :submissions, only: [:new, :create, :show]
    end
    resources :teams, only: :show
    member do
      get :public
    end
  end

  # Staff routes.
  ###############

  namespace :staff do
    root to: "main#dashboard"

    resource :settings, only: [:edit, :update]
    resources :users
    resources :terms
    resources :courses do
        resources :assignments
    end
  end
end

Bottlenose::Application.routes.draw do
  # Using devise for user auth.
  devise_for :users

  # Student routes.
  #################

  root to: "main#home"
  get "about" => "main#about"

  resources :terms

  resources :courses do
    resources :registrations, except: [:edit, :update] do
      collection do
        post :bulk
      end
      member do
        post :toggle
      end
    end
    resources :reg_requests, only: [:new, :create]
    resources :assignments do
      resources :submissions
    end
    resources :teams do
      member do
        patch :disolve
      end
    end
    member do
      get :public
    end
  end

  # Staff routes.
  ###############

  namespace :staff do
    root to: "main#dashboard"

    resource :settings, only: [:edit, :update]
    resources :users do
      collection do
        post :stop_impersonating
      end
      member do
        post :impersonate
      end
    end
    resources :terms
    resources :courses do
      delete 'reg_requests/:id/accept', to: 'reg_requests#accept', as: 'reg_request_accept'
      delete 'reg_requests/:id/reject', to: 'reg_requests#reject', as: 'reg_request_reject'
      resources :registrations, except: [:edit, :update] do
        collection do
          post :bulk
        end
        member do
          post :toggle
        end
      end
      resources :teams do
        member do
          patch :disolve
        end
      end
      resources :assignments do
        resources :submissions
      end
    end
  end
end

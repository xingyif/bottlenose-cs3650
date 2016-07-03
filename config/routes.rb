Bottlenose::Application.routes.draw do
  # Using devise for user auth.
  devise_for :users, :skip => [:registrations]

  root to: "main#home"
  get "about" => "main#about"

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
    resources :registrations, except: [:edit, :update] do
      collection do
        post :bulk
      end
      member do
        post :toggle
      end
    end
    resources :reg_requests, only: [:new, :create]
    delete 'reg_requests/:id/accept', to: 'reg_requests#accept', as: 'reg_request_accept'
    delete 'reg_requests/:id/reject', to: 'reg_requests#reject', as: 'reg_request_reject'
    delete 'reg_requests/:course_id/accept_all', to: 'reg_requests#accept_all', as: 'reg_request_accept_all'
    delete 'reg_requests/:course_id/reject_all', to: 'reg_requests#reject_all', as: 'reg_request_reject_all'
    resources :assignments do
      resources :submissions do
        member do
          get :files
        end
      end
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

  get 'courses/:course_id/assignments/:id/tarball' => 'assignments#tarball', as: 'course_assignment_tarball'

  # # Staff routes.
  # ###############
  #
  # namespace :staff do
  #   root to: "main#dashboard"
  #
  #   resource :settings, only: [:edit, :update]
  #   resources :users do
  #     collection do
  #       post :stop_impersonating
  #     end
  #     member do
  #       post :impersonate
  #     end
  #   end
  #   resources :terms
  #   resources :courses do
  #     delete 'reg_requests/:id/accept', to: 'reg_requests#accept', as: 'reg_request_accept'
  #     delete 'reg_requests/:id/reject', to: 'reg_requests#reject', as: 'reg_request_reject'
  #     resources :registrations, except: [:edit, :update] do
  #       collection do
  #         post :bulk
  #       end
  #       member do
  #         post :toggle
  #       end
  #     end
  #     resources :teams do
  #       member do
  #         patch :disolve
  #       end
  #     end
  #     resources :assignments do
  #       resources :submissions
  #     end
  #   end
  # end
end

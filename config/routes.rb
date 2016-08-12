Bottlenose::Application.routes.draw do
  # Using devise for user auth.
  devise_for :users, :skip => [:registrations, :passwords]

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
      collection do
        get 'weights' => 'assignments#edit_weights'
        post 'weights' => 'assignments#update_weights'
      end
      member do
        post 'create_missing_graders' => 'assignments#recreate_graders'
      end
      resources :submissions do
        member do
          get :files
          get :use, to: 'submissions#use_for_grading', as: 'use'
          patch :publish, to: 'submissions#publish', as: 'publish'
          post 'recreate/:grader_config_id', to: 'submissions#recreate_grader', as: 'recreate_grader'
        end
        resources :graders, only: [:show, :edit, :update] do
          member do
            post :regrade
          end
        end
      end
    end
    resources :teams do
      member do
        patch :disolve
      end
      collection do
        patch :disolve_all
        patch :randomize
      end
    end
    member do
      get :public
      get :gradesheet
    end
  end

  get 'courses/:course_id/assignments/:id/user/:user_id' => 'assignments#show_user', as: 'course_assignment_user'
  get 'courses/:course_id/assignments/:id/tarball' => 'assignments#tarball', as: 'course_assignment_tarball'
  patch 'courses/:course_id/assignments/:id/publish' => 'assignments#publish', as: 'course_assignment_publish'

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

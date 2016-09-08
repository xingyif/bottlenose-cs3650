Bottlenose::Application.routes.draw do
  # Using devise for user auth.
  devise_for :users, :skip => [:registrations, :passwords]

  root to: "main#home"
  get "about" => "main#about"

  resource :settings, only: [:edit, :update]

  resources :users, except: [:destroy] do
    collection do
      post :stop_impersonating
      get :lookup, to: 'users#lookup'
    end
    member do
      post :impersonate
    end
  end

  resources :terms

  resources :courses, except: [:destroy] do
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
      resources :grader_configs, only: [] do
        member do
          get 'bulk' => 'graders#bulk_edit'
          post 'bulk' => 'graders#bulk_update'
        end
      end
      resources :submissions, except: [:edit, :update, :destroy] do
        member do
          get :details
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
    resources :teams, except: [:edit, :update, :destroy] do
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
      get :facebook
      delete :withdraw
    end
  end

  get   'courses/:course_id/assignments/:id/user/:user_id' => 'assignments#show_user', as: 'course_assignment_user'
  get   'courses/:course_id/assignments/:id/tarball' => 'assignments#tarball', as: 'course_assignment_tarball'
  patch 'courses/:course_id/assignments/:id/publish' => 'assignments#publish', as: 'course_assignment_publish'


  Bottlenose::Application.routes.draw do
    match "/500", :to => "errors#internal_server_error", :via => :all
    get "*any", via: :all, to: "errors#not_found"
  end
end

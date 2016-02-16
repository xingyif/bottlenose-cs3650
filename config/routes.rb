
Bottlenose::Application.routes.draw do
  devise_for :users

  # TODO: This page is currently the not logged in landing page.
  # but it should be meaningful as a dashboard for users.
  get "main/index"

  # TODO: I'd like things like this to be under an admin namespace.
  get  'settings' => 'settings#index'
  post 'settings/save'

  resources :terms

  resources :courses do
    resources :registrations
    resources :reg_requests
    resources :buckets
    resources :assignments
    resources :teams do
      patch :divorce
    end
  end

  post 'courses/:id/export_grades'  => 'courses#export_grades'
  post 'courses/:id/export_summary' => 'courses#export_summary'
  get  'courses/:id/bulk_add'       => 'courses#bulk_add'
  post 'courses/:id/bulk_add'       => 'courses#bulk_add'
  get  'courses/:id/public'         => 'courses#public'

  resources :registrations, except: [:new]

  get 'registrations/:id/submissions_for_assignment/:assignment_id' =>
    'registrations#submissions_for_assignment'

  post 'registrations/:id/toggle_show' => 'registrations#toggle_show'

  resources :reg_requests, except: [:new]

  resources :assignments do
    resources :submissions, except: [:destroy]
  end

  get 'assignments/:assignment_id/manual_grade' =>
    'submissions#manual_grade'

  get 'assignments/:id/tarball' =>
    'assignments#tarball'

  resources :submissions, except: [:destroy]

  root :to => 'main#index'

  namespace :admin do
    resources :users
    post 'users/:id/impersonate' => 'users#impersonate'
  end
end

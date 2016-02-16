
Bottlenose::Application.routes.draw do
  # Using devise for user auth.
  devise_for :users
  root to: "main#dashboard"
  get "landing" => "main#landing"
  get "about" => "main#about"

  # TODO: Should this even be a route?
  resources :terms, only: [:index, :show]

  resources :courses, only: [:index, :show] do
    resources :reg_requests, only: [:new, :create, :update]  # TODO: Update?
    resources :buckets  # TODO
    resources :assignments, only: [:index, :show] do
      resources :submissions, except: [:destroy]
      # TODO: Download route?
    end
    resources :teams, only: [:index, :show]
    # TODO
    # get 'courses/:id/public' => 'courses#public'
  end

  # # Admin routes.
  # namespace :admin do
  #   resource :settings, only: [:edit, :update]
  #
  #   resources :users do
  #     member do
  #       post :impersonate
  #     end
  #   end
  #
  #   resources :registrations do
  #     post 'registrations/:id/toggle_show' => 'registrations#toggle_show'
  #   end
  #
  #   resources :reg_requests
  #
  #   resources :courses do
  #     resources :assignments do
  #       resources :submissions
  #       get 'assignments/:assignment_id/manual_grade' => 'submissions#manual_grade'
  #       get 'assignments/:id/tarball' => 'assignments#tarball'
  #     end
  #     post 'courses/:id/export_grades'  => 'courses#export_grades'
  #     post 'courses/:id/export_summary' => 'courses#export_summary'
  #     get  'courses/:id/bulk_add'       => 'courses#bulk_add'
  #     post 'courses/:id/bulk_add'       => 'courses#bulk_add'
  #   end
  # end
end

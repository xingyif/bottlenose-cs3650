Bottlenose::Application.routes.draw do
  # Using devise for user auth.
  devise_for :users
  root to: "main#home"
  get "about" => "main#about"

  resources :courses, only: [:index, :show] do
    resources :reg_requests, only: [:new, :create]
    resources :assignments, only: :show do
      resources :submissions, except: [:destroy]
    end
    resources :teams, only: :show
    # TODO: get 'courses/:id/public' => 'courses#public'
  end
end

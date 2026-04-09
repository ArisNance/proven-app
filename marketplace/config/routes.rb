require "sidekiq/web"

Rails.application.routes.draw do
  root "home#index"

  devise_for :users, controllers: {
    omniauth_callbacks: "users/omniauth_callbacks",
    registrations: "users/registrations"
  }

  resources :products, only: %i[index show]

  namespace :makers do
    get "onboarding", to: "onboarding#show"
    post "onboarding", to: "onboarding#create"
    resources :shops, only: %i[index new create show]
  end

  namespace :admin do
    get "/", to: "dashboard#index", as: :root
    get "login", to: "sessions#new"
    post "login", to: "sessions#create"
    get "logout", to: "sessions#destroy"
    delete "logout", to: "sessions#destroy"

    resources :users, only: %i[index show update destroy]
    resources :shops, only: %i[index show update destroy]
    resources :products, only: %i[index show update destroy]
    resources :messages, only: %i[index show destroy]
    resources :approvals, only: %i[index] do
      member do
        post :approve
        post :reject
      end
    end
  end

  namespace :webhooks do
    post "stripe", to: "stripe#create"
    post "shipstation", to: "shipstation#create"
  end

  namespace :shopify do
    get "oauth/start", to: "oauth#start"
    post "oauth/callback", to: "oauth#callback"
    post "sync/run", to: "sync#run"
  end

  resources :conversations, only: %i[index show create] do
    resources :messages, only: %i[create]
  end

  resources :dashboard, only: %i[index]

  get "/404", to: "errors#not_found"
  get "/422", to: "errors#unprocessable"
  get "/500", to: "errors#internal"

  mount Sidekiq::Web => "/sidekiq" if Rails.env.development?
end

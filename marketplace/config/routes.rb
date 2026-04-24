require "sidekiq/web"

Rails.application.routes.draw do
  get "favicon.ico", to: "favicon#show"
  root "home#index"

  devise_for :users, controllers: {
    omniauth_callbacks: "users/omniauth_callbacks",
    registrations: "users/registrations"
  }

  resources :products, only: %i[index show] do
    member do
      post :favorite, to: "product_favorites#create"
      delete :favorite, to: "product_favorites#destroy"
    end
  end
  get "storefront/cart", to: "storefront/cart#show", as: :storefront_cart
  patch "storefront/cart/items/:product_id", to: "storefront/cart#update_item", as: :storefront_cart_update_item
  delete "storefront/cart/items/:product_id", to: "storefront/cart#remove_item", as: :storefront_cart_remove_item
  delete "storefront/cart/clear", to: "storefront/cart#clear", as: :storefront_cart_clear
  post "shops/:id/favorite", to: "shop_favorites#create", as: :favorite_shop
  delete "shops/:id/favorite", to: "shop_favorites#destroy"
  get "checkout", to: "checkout#new", as: :checkout
  post "checkout/place_order", to: "checkout#place_order", as: :checkout_place_order
  post "checkout/:product_id", to: "checkout#create", as: :checkout_create
  get "checkout/success", to: "checkout#success", as: :checkout_success
  get "checkout/cancel", to: "checkout#cancel", as: :checkout_cancel

  namespace :makers do
    get "onboarding", to: "onboarding#show"
    post "onboarding", to: "onboarding#create"
    get "profile_onboarding", to: "profile_onboarding#show"
    post "profile_onboarding", to: "profile_onboarding#create"
    get "profile/:username", to: "profiles#show", as: :public_profile
    resources :shops, only: %i[index new create show] do
      member do
        post :connect_billing
        post :sync_billing
      end
    end
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
    resources :maker_applications, only: %i[index show update] do
      member do
        post :approve
        post :reject
      end
    end
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
    get "oauth/callback", to: "oauth#callback"
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

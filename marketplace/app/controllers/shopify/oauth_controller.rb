module Shopify
  class OauthController < ApplicationController
    skip_before_action :verify_authenticity_token, only: :callback

    def start
      shop = params.fetch(:shop)
      redirect_to ShopifyOauthService.authorization_url(shop)
    end

    def callback
      ShopifyOauthService.exchange!(params.to_unsafe_h)
      render json: { status: "connected" }
    rescue StandardError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end
end

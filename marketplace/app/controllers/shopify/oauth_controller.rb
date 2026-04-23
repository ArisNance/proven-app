module Shopify
  class OauthController < ApplicationController
    before_action :authenticate_user!, only: :start
    skip_before_action :verify_authenticity_token, only: :callback

    def start
      shop = params.fetch(:shop)
      state = SecureRandom.hex(24)
      session[:shopify_oauth_state] = state
      session[:shopify_oauth_user_id] = current_user.id

      redirect_to ShopifyOauthService.authorization_url(shop, state: state), allow_other_host: true
    end

    def callback
      expected_state = session.delete(:shopify_oauth_state)
      user_id = session.delete(:shopify_oauth_user_id)
      raise ShopifyOauthService::InvalidOauth, "Could not resolve user for Shopify connection" if user_id.blank?

      connection = ShopifyOauthService.exchange!(
        params.to_unsafe_h,
        expected_state: expected_state,
        user_id: user_id
      )

      render json: { status: "connected", shop_domain: connection.shop_domain, connection_id: connection.id }
    rescue ShopifyOauthService::InvalidOauth => e
      render json: { error: e.message }, status: :unprocessable_entity
    rescue StandardError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end
end

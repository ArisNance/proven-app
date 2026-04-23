module Shopify
  class SyncController < ApplicationController
    before_action :authenticate_user!

    def run
      ShopifySyncJob.perform_async(current_user.id, params[:connection_id])
      render json: { status: "queued", user_id: current_user.id }
    end
  end
end

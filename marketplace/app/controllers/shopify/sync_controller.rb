module Shopify
  class SyncController < ApplicationController
    before_action :authenticate_user!

    def run
      ShopifySyncJob.perform_async(current_user.id)
      render json: { status: "queued" }
    end
  end
end

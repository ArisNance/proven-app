class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    @conversations = current_user.conversations.includes(:messages, :buyer, :maker)
    @recent_messages = @conversations.flat_map(&:messages).sort_by(&:created_at).last(5).reverse

    @shops = current_user.maker? || current_user.admin? ? current_user.shops.includes(:shop_approval) : Shop.none
    @pending_shop_approvals = ShopApproval.pending.count
    @pending_product_approvals = ProductApproval.pending.count
    @open_flags = FlaggedItem.open.count

    @first_time_user = if current_user.maker?
      current_user.maker_profile.blank? || @shops.empty?
    elsif current_user.buyer?
      @conversations.empty?
    else
      @pending_shop_approvals.zero? && @pending_product_approvals.zero?
    end
  end
end

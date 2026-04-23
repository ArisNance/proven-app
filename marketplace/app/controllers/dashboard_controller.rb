class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    if current_user.admin? && !current_user.seller_account?
      redirect_to admin_root_path and return
    end

    if current_user.seller_account?
      load_seller_dashboard
      render :maker
    else
      load_buyer_dashboard
      render :buyer
    end
  end

  private

  def load_buyer_dashboard
    @orders = recent_orders_for_user(current_user, limit: 8)
    @completed_orders = @orders.select { |order| completed_order?(order) }
    @orders_total = @completed_orders.size
    @orders_total_spend = @completed_orders.sum { |order| order_total_cents(order) }
    @recent_messages = current_user.conversations.includes(:messages).flat_map(&:messages).sort_by(&:created_at).last(5).reverse
    @maker_application = current_user.maker_application
    @show_sell_on_proven = current_user.buyer_only? && (@maker_application.blank? || @maker_application.rejected?)
  end

  def load_seller_dashboard
    @shops = current_user.shops.includes(:shop_approval, :listing_fee_subscriptions).order(created_at: :desc)
    @conversations = current_user.conversations.includes(:messages, :buyer, :maker)
    @recent_messages = @conversations.flat_map(&:messages).sort_by(&:created_at).last(6).reverse
    @products_count = Storefront::Catalog.all.count { |product| @shops.map(&:id).include?(product.source_shop_id.to_i) }
    @pending_shop_approvals = @shops.count { |shop| shop.shop_approval&.pending? }
    @approved_shop_count = @shops.count(&:approved?)
    @maker_application = current_user.maker_application
    @maker_onboarding_profile = current_user.maker_onboarding_profile
  end

  def recent_orders_for_user(user, limit:)
    return [] unless defined?(Spree::Order)
    return [] unless Spree::Order.column_names.include?("user_id")

    Spree::Order.where(user_id: user.id).order(created_at: :desc).limit(limit)
  rescue StandardError
    []
  end

  def completed_order?(order)
    state = order.try(:state).to_s
    payment_state = order.try(:payment_state).to_s
    state == "complete" || payment_state == "paid"
  end

  def order_total_cents(order)
    total_value = order.try(:total).to_f
    (total_value * 100).to_i
  end
end

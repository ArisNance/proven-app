module Admin
  class DashboardController < BaseController
    def index
      @users_count = User.count
      @shops_count = Shop.count
      @messages_count = Message.count
      @products_count = catalog_products.count
      @catalog_value_cents = catalog_products.sum { |product| product.price_cents.to_i }
      @maker_applications_pending = MakerApplication.where(state: %i[submitted in_review]).count
      @applicants_need_review = ShopApproval.pending.count + ProductApproval.pending.count + @maker_applications_pending
      @recent_users = User.order(created_at: :desc).limit(6)
      @recent_messages = Message.includes(:sender).order(created_at: :desc).limit(6)
    end

    private

    def catalog_products
      @catalog_products ||= Storefront::Catalog.all
    end
  end
end

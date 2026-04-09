module Admin
  class ShopsController < BaseController
    def index
      @shops = Shop.includes(:maker, :shop_approval).order(created_at: :desc)
    end

    def show
      @shop = Shop.includes(:maker, :shop_approval).find(params[:id])
      @catalog_products = Storefront::Catalog.all.select { |product| product.source_shop_id.to_i == @shop.id }
    end

    def update
      shop = Shop.find(params[:id])

      if shop.update(shop_params)
        redirect_to admin_shop_path(shop), notice: "Shop updated."
      else
        @shop = shop
        @catalog_products = []
        render :show, status: :unprocessable_entity
      end
    end

    def destroy
      shop = Shop.find(params[:id])
      name = shop.name
      shop.destroy!
      redirect_to admin_shops_path, notice: "Shop #{name} removed."
    rescue StandardError => e
      redirect_to admin_shops_path, alert: "Could not delete shop: #{e.message}"
    end

    private

    def shop_params
      params.require(:shop).permit(:name, :description, :state)
    end
  end
end

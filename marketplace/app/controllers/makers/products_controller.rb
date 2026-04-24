module Makers
  class ProductsController < ApplicationController
    before_action :authenticate_user!
    before_action :set_shop
    before_action :ensure_upload_access!

    def index
      @products = shop_products
      @product_approvals = ProductApproval.where(product_id: spree_product_ids(@products)).index_by(&:product_id)
    end

    def new
      @product_draft = Makers::ProductDraft.new
    end

    def create
      @product_draft = Makers::ProductDraft.new(product_draft_params)
      @product_draft.shop = @shop
      @product_draft.user = current_user

      if @product_draft.save
        redirect_to makers_shop_products_path(@shop), notice: "Product submitted. It is now in the approval queue."
      else
        render :new, status: :unprocessable_entity
      end
    end

    private

    def set_shop
      @shop = current_user.shops.find(params[:shop_id])
    end

    def ensure_upload_access!
      return if @shop.approved?

      redirect_to makers_shop_path(@shop), alert: "Product uploads unlock after shop approval."
    end

    def product_draft_params
      params.require(:makers_product_draft).permit(
        :name,
        :description,
        :category,
        :material,
        :price,
        :image_url,
        :size_values,
        :color_values
      )
    end

    def shop_products
      Storefront::Catalog.all.select { |product| product.source_shop_id.to_i == @shop.id }.sort_by { |product| product.created_at || Time.at(0) }.reverse
    end

    def spree_product_ids(products)
      products.filter_map do |product|
        match = product.id.to_s.match(/\Aspree-(\d+)\z/)
        match && match[1].to_i
      end
    end
  end
end

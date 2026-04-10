module Admin
  class ProductsController < BaseController
    def index
      @query = params[:q].to_s.strip
      @products = if defined?(Spree::Product)
        scope = Spree::Product.order(created_at: :desc)
        scope = scope.where("name ILIKE ?", "%#{@query}%") if @query.present?
        scope.limit(500)
      else
        []
      end
    end

    def show
      @product = find_product!(params[:id])
    end

    def update
      product = find_product!(params[:id])
      product.assign_attributes(product_params)

      if params[:spree_product][:price].present? && product.respond_to?(:price=)
        product.price = params[:spree_product][:price]
      end

      if product.save
        redirect_to admin_product_path(product), notice: "Product updated."
      else
        @product = product
        render :show, status: :unprocessable_entity
      end
    rescue StandardError => e
      redirect_to admin_product_path(params[:id]), alert: "Could not update product: #{e.message}"
    end

    def destroy
      product = find_product!(params[:id])
      product_name = product.name
      product.destroy!
      redirect_to admin_products_path, notice: "Product #{product_name} removed."
    rescue StandardError => e
      redirect_to admin_products_path, alert: "Could not delete product: #{e.message}"
    end

    private

    def find_product!(identifier)
      token = identifier.to_s
      return Spree::Product.find(token) if token.match?(/\A\d+\z/)

      Spree::Product.find_by!(slug: token)
    end

    def product_params
      params.require(:spree_product).permit(:name, :description, :status)
    end
  end
end

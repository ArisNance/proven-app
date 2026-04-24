module Storefront
  class CartController < ApplicationController
    def show
      @cart = cart
      @items = @cart.items
    end

    def update_item
      cart.update_quantity(params[:product_id], params[:quantity])
      redirect_to storefront_cart_path, notice: "Cart updated."
    end

    def remove_item
      cart.remove(params[:product_id])
      redirect_to storefront_cart_path, notice: "Item removed from cart."
    end

    def clear
      cart.clear!
      redirect_to storefront_cart_path, notice: "Cart cleared."
    end

    private

    def cart
      @cart ||= Storefront::Cart.new(session: session)
    end
  end
end

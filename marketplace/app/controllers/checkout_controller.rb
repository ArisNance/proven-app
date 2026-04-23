class CheckoutController < ApplicationController
  def create
    product = Storefront::Catalog.find(params[:product_id])
    return redirect_to products_path, alert: "Product not found." if product.blank?

    session = Payments::CheckoutService.create_product_checkout!(
      product: product,
      quantity: params[:quantity],
      buyer_email: current_user&.email
    )
    raise Payments::CheckoutService::ConfigurationError, "Stripe checkout URL was not returned" if session.url.blank?

    redirect_to session.url, allow_other_host: true
  rescue Payments::CheckoutService::ConfigurationError => e
    redirect_to product_path_for(product), alert: e.message
  rescue Stripe::StripeError => e
    redirect_to product_path_for(product), alert: "Unable to start checkout: #{e.message}"
  end

  def success
    @checkout_session_id = params[:session_id].to_s
    @checkout_session = fetch_checkout_session(@checkout_session_id)
  end

  def cancel
  end

  private

  def product_path_for(product)
    return products_path if product.blank?

    product_path(product.slug.presence || product.id)
  end

  def fetch_checkout_session(session_id)
    return if session_id.blank? || ENV["STRIPE_SECRET_KEY"].blank?

    Stripe::Checkout::Session.retrieve(session_id)
  rescue Stripe::StripeError => e
    Rails.logger.warn("Checkout session lookup failed for #{session_id}: #{e.message}")
    nil
  end
end

class CheckoutController < ApplicationController
  def new
    @cart = storefront_cart
    @cart_items = @cart.items
    @subtotal_cents = @cart.subtotal_cents
    return redirect_to products_path, alert: "Your bag is empty." if @cart_items.empty?

    @checkout_form = CheckoutForm.new(default_checkout_form_attributes)
  end

  def create
    product = Storefront::Catalog.find(params[:product_id])
    return redirect_to products_path, alert: "Product not found." if product.blank?

    quantity = normalize_quantity(params[:quantity])
    checkout_action = params[:checkout_action].to_s

    case checkout_action
    when "add_to_bag"
      storefront_cart.add_product(product, quantity: quantity)
      redirect_to storefront_cart_path, notice: "#{product.name} added to your bag."
    when "buy_now"
      storefront_cart.add_product(product, quantity: quantity)
      redirect_to checkout_path
    else
      create_stripe_checkout_session!(product: product, quantity: quantity)
    end
  rescue Payments::CheckoutService::ConfigurationError => e
    redirect_to product_path_for(product), alert: e.message
  rescue Stripe::StripeError => e
    redirect_to product_path_for(product), alert: "Unable to start checkout: #{e.message}"
  end

  def place_order
    @cart = storefront_cart
    @cart_items = @cart.items
    @subtotal_cents = @cart.subtotal_cents

    if @cart_items.empty?
      return redirect_to products_path, alert: "Your bag is empty."
    end

    @checkout_form = CheckoutForm.new(checkout_form_params)
    @checkout_form.email = current_user.email if user_signed_in? && @checkout_form.email.blank?

    if @checkout_form.valid?
      order = CheckoutOrder.create!(build_checkout_order_attributes(@checkout_form))
      ShipstationOrderPushJob.perform_async(order.id)
      @cart.clear!

      redirect_to checkout_success_path(reference: order.reference_code), notice: "Order submitted. We are preparing shipping details now."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def success
    @checkout_reference = params[:reference].to_s
    @checkout_order = find_checkout_order(@checkout_reference)

    return if @checkout_order.present?

    @checkout_session_id = params[:session_id].to_s
    @checkout_session = fetch_checkout_session(@checkout_session_id)
  end

  def cancel
  end

  private

  def create_stripe_checkout_session!(product:, quantity:)
    session = Payments::CheckoutService.create_product_checkout!(
      product: product,
      quantity: quantity,
      buyer_email: current_user&.email
    )
    raise Payments::CheckoutService::ConfigurationError, "Stripe checkout URL was not returned" if session.url.blank?

    redirect_to session.url, allow_other_host: true
  end

  def normalize_quantity(value)
    quantity = value.to_i
    quantity = 1 if quantity <= 0
    quantity > 25 ? 25 : quantity
  end

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

  def find_checkout_order(reference)
    return if reference.blank?

    order = CheckoutOrder.find_by(reference_code: reference)
    return if order.blank?
    return order if order.user_id.blank?
    return order if user_signed_in? && order.user_id == current_user.id

    nil
  end

  def storefront_cart
    @storefront_cart ||= Storefront::Cart.new(session: session)
  end

  def default_checkout_form_attributes
    {
      email: current_user&.email,
      country: "US"
    }
  end

  def checkout_form_params
    params.require(:checkout_form).permit(
      :email,
      :first_name,
      :last_name,
      :phone,
      :address1,
      :address2,
      :city,
      :state,
      :postal_code,
      :country,
      :shipping_notes
    )
  end

  def build_checkout_order_attributes(form)
    {
      user: current_user,
      email: form.email,
      first_name: form.first_name,
      last_name: form.last_name,
      phone: form.phone,
      address1: form.address1,
      address2: form.address2,
      city: form.city,
      state: form.state,
      postal_code: form.postal_code,
      country: form.country,
      shipping_notes: form.shipping_notes,
      total_cents: @subtotal_cents,
      currency: "USD",
      cart_snapshot: @cart.snapshot,
      submitted_at: Time.current
    }
  end
end

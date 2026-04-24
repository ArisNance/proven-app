module ApplicationHelper
  def current_role
    return @current_role if defined?(@current_role)
    return @current_role = :guest unless user_signed_in?
    return @current_role = :maker if selected_dashboard_mode == :maker

    @current_role = :buyer
  end

  def selected_dashboard_mode
    return @selected_dashboard_mode if defined?(@selected_dashboard_mode)
    return @selected_dashboard_mode = :buyer unless user_signed_in?
    return @selected_dashboard_mode = :buyer unless current_user.seller_account?

    @selected_dashboard_mode = (session[:dashboard_mode].to_s.presence_in(%w[buyer maker]) || "maker").to_sym
  end

  def dashboard_mode_switch_enabled?
    user_signed_in? && current_user.seller_account?
  end

  def dashboard_mode_label
    selected_dashboard_mode == :maker ? "Maker Workspace" : "Buyer Workspace"
  end

  def dashboard_destination_path
    dashboard_mode_switch_enabled? ? dashboard_index_path(mode: selected_dashboard_mode) : dashboard_index_path
  end

  def role_badge_text
    case current_role
    when :maker then "Maker"
    when :buyer then "Buyer"
    else "Guest"
    end
  end

  def header_navigation_items
    [
      { label: "Home", path: root_path },
      { label: "Shop", path: products_path }
    ]
  end

  def header_dropdown_items
    items = []

    if user_signed_in?
      items << { label: "Dashboard", path: dashboard_destination_path }
      items << { label: "Messages", path: conversations_path }
      items << { label: "My Shop", path: makers_shops_path } if current_user.seller_account?
      items << { label: "Sell on Proven", path: makers_onboarding_path } if sell_on_proven_eligible?
    else
      items << { label: "Sign in", path: new_user_session_path }
      items << { label: "Join", path: new_user_registration_path }
    end

    items << { label: "Admin Panel", path: admin_root_path } if admin_session_authenticated?
    items << { label: "Admin Login", path: admin_login_path } if !user_signed_in? && !admin_session_authenticated?
    items
  end

  def admin_session_authenticated?
    session[:proven_admin_authenticated] == true &&
      session[:proven_admin_seeded_login].to_s == Admin::SessionsController::ADMIN_USERNAME
  end

  def cart_item_count
    @cart_item_count ||= Storefront::Cart.new(session: session).item_count
  rescue StandardError
    0
  end

  def role_quick_actions
    case current_role
    when :maker
      actions = []
      if can_create_shop?
        actions << { label: "Create shop", path: new_makers_shop_path, style: :primary }
      else
        primary_shop = current_user.shops.order(created_at: :asc).first
        actions << { label: "Manage shop", path: makers_shop_path(primary_shop), style: :primary } if primary_shop.present?
      end
      actions << { label: "Maker onboarding", path: makers_profile_onboarding_path, style: :secondary }
      actions
    when :buyer
      actions = [
        { label: "View dashboard", path: dashboard_destination_path, style: :primary },
        { label: "Open messages", path: conversations_path, style: :secondary }
      ]
      actions << { label: "Sell on Proven", path: makers_onboarding_path, style: :secondary } if sell_on_proven_eligible?
      actions
    else
      [
        { label: "Sign in", path: new_user_session_path, style: :primary },
        { label: "Create account", path: new_user_registration_path, style: :secondary }
      ]
    end
  end

  def sell_on_proven_eligible?
    return false unless user_signed_in?
    return false if current_user.admin?
    return false if current_user.shops.exists?
    return false if current_user.seller_account?

    maker_application = current_user.maker_application
    maker_application.blank? || maker_application.rejected?
  end

  def can_create_shop?
    return false unless user_signed_in?

    current_user.shops.none?
  end

  def nav_link_classes(active)
    base = "rounded-full px-3 py-2 text-sm font-medium transition duration-200 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-accent"
    active ? "#{base} bg-black text-[#FAFAF8]" : "#{base} text-[#4A4A42] hover:text-black hover:bg-black/5"
  end

  def quick_action_classes(style)
    base = "inline-flex items-center justify-center rounded-full px-4 py-2 text-sm font-semibold transition duration-200 hover:-translate-y-0.5 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-accent"
    style == :primary ? "#{base} bg-[#D4F93D] text-black hover:bg-[#B8DC28]" : "#{base} border border-[#CCCCC4] bg-white text-[#0D0D0D] hover:border-[#0D0D0D]"
  end

  def status_pill_class(state)
    case state.to_s
    when "approved", "active", "resolved"
      "status-pill bg-emerald-50 text-emerald-700"
    when "pending", "open"
      "status-pill bg-amber-50 text-amber-800"
    when "rejected", "suspended", "canceled"
      "status-pill bg-rose-50 text-rose-700"
    else
      "status-pill bg-slate-100 text-slate-700"
    end
  end

  def inline_field_error(record, field)
    return unless record&.errors&.[](field)&.any?

    content_tag(:p, record.errors.full_messages_for(field).first, class: "field-error", id: "#{record.model_name.singular}_#{field}_error")
  end
end

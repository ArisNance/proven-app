module ApplicationHelper
  def current_role
    return :guest unless user_signed_in?
    return :admin if current_user.admin?
    return :maker if current_user.seller_account?

    :buyer
  end

  def role_badge_text
    case current_role
    when :admin then "Admin"
    when :maker then "Maker"
    when :buyer then "Buyer"
    else "Guest"
    end
  end

  def primary_navigation_items
    items = [{ label: "Home", path: root_path, roles: %i[guest buyer maker admin] }, { label: "Shop", path: products_path, roles: %i[guest buyer maker admin] }]
    items << { label: "Dashboard", path: dashboard_index_path, roles: %i[buyer maker admin] }
    items << { label: "Messages", path: conversations_path, roles: %i[buyer maker admin] }
    items << { label: "My Shop", path: makers_shops_path, roles: %i[maker admin] }
    items << { label: "Sell on Proven", path: makers_onboarding_path, roles: [] } if sell_on_proven_eligible?

    visible_items = items.select { |item| item[:roles].include?(current_role) }
    visible_items << { label: "Admin Panel", path: admin_root_path, roles: [] } if session[:proven_admin_authenticated] == true
    visible_items << { label: "Admin Login", path: admin_login_path, roles: [] } if current_role == :guest && session[:proven_admin_authenticated] != true
    visible_items
  end

  def role_quick_actions
    case current_role
    when :admin
      [
        { label: "Review approvals", path: admin_approvals_path, style: :primary },
        { label: "Open dashboard", path: dashboard_index_path, style: :secondary }
      ]
    when :maker
      [
        { label: "Create shop", path: new_makers_shop_path, style: :primary },
        { label: "Maker onboarding", path: makers_profile_onboarding_path, style: :secondary }
      ]
    when :buyer
      actions = [
        { label: "View dashboard", path: dashboard_index_path, style: :primary },
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
    return false if current_user.seller_account?

    maker_application = current_user.maker_application
    maker_application.blank? || maker_application.rejected?
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

module Admin
  class ApprovalsController < BaseController

    def index
      @shop_approvals = ShopApproval.pending.includes(:shop).order(created_at: :asc)
      @product_approvals = ProductApproval.pending.includes(:product).order(created_at: :asc)
      @flagged_items = FlaggedItem.open.includes(:product).order(created_at: :asc)
      @maker_applications = MakerApplication.where(state: %i[submitted in_review]).includes(:user).order(submitted_at: :asc, created_at: :asc)
    end

    def approve
      approval = find_approval
      approval.update!(state: :approved, reviewer: admin_reviewer, reviewed_at: Time.current)
      redirect_to admin_approvals_path, notice: "Approval recorded"
    end

    def reject
      approval = find_approval
      approval.update!(state: :rejected, reviewer: admin_reviewer, reviewed_at: Time.current)
      redirect_to admin_approvals_path, alert: "Item rejected"
    end

    private

    def find_approval
      ShopApproval.find_by(id: params[:id]) || ProductApproval.find(params[:id])
    end

    def admin_reviewer
      User.admin.first || User.first
    end
  end
end

module Admin
  class UsersController < BaseController
    def index
      @users = User.order(created_at: :desc)
    end

    def show
      @user = User.find(params[:id])
      @conversations_count = @user.conversations.count
      @messages_count = @user.messages.count
      @shops_count = @user.shops.count
    end

    def update
      user = User.find(params[:id])

      if user.update(user_params)
        redirect_to admin_user_path(user), notice: "User updated."
      else
        @user = user
        @conversations_count = @user.conversations.count
        @messages_count = @user.messages.count
        @shops_count = @user.shops.count
        render :show, status: :unprocessable_entity
      end
    end

    def destroy
      user = User.find(params[:id])
      email = user.email
      user.destroy!
      redirect_to admin_users_path, notice: "User #{email} removed."
    rescue StandardError => e
      redirect_to admin_users_path, alert: "Could not delete user: #{e.message}"
    end

    private

    def user_params
      params.require(:user).permit(:role)
    end
  end
end

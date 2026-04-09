class ShopPolicy < ApplicationPolicy
  def create?
    user&.maker?
  end

  def show?
    user&.admin? || record.maker_id == user.id
  end
end

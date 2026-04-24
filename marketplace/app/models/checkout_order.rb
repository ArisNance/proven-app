class CheckoutOrder < ApplicationRecord
  enum status: {
    submitted: 0,
    shipstation_submitted: 1,
    shipstation_failed: 2
  }, _default: :submitted

  belongs_to :user, optional: true

  before_validation :ensure_reference_code

  validates :reference_code, :email, :first_name, :last_name, :address1, :city, :state, :postal_code, :country, presence: true
  validates :reference_code, uniqueness: true
  validates :total_cents, numericality: { greater_than: 0 }

  private

  def ensure_reference_code
    return if reference_code.present?

    self.reference_code = loop do
      token = "PVN-#{SecureRandom.hex(4).upcase}"
      break token unless self.class.exists?(reference_code: token)
    end
  end
end

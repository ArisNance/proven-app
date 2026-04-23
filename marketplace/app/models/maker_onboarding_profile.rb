class MakerOnboardingProfile < ApplicationRecord
  MAIN_PRODUCT_CATEGORIES = [
    "Textiles & Fiber",
    "Woodworking",
    "Ceramics",
    "Jewelry",
    "Candles & Home Fragrance",
    "Art & Illustration",
    "Basketry & Weaving",
    "Leather Goods",
    "Glass",
    "Sculptures",
    "Paper Products",
    "Toys",
    "Pet Goods",
    "Natural & Botanical",
    "Cottage Law Food",
    "Home Decor",
    "Other"
  ].freeze

  LEAD_TIME_OPTIONS = [
    "1-2 days",
    "2-4 days",
    "4-7 days",
    "7-10 days",
    "1-2 weeks",
    "2-3 weeks",
    "3-4 weeks",
    "Longer than 1 month"
  ].freeze

  enum state: { draft: 0, completed: 1 }

  belongs_to :user
  belongs_to :maker_application, optional: true
  belongs_to :shop, optional: true

  validates :legal_first_name, :legal_last_name, :legal_business_name, :tax_identifier, :dba_business_name, :username,
    :main_product_category, :lead_time_for_fulfillment, :shipping_policy, :privacy_policy,
    presence: true
  validates :username, uniqueness: { case_sensitive: false }
  validates :main_product_category, inclusion: { in: MAIN_PRODUCT_CATEGORIES }
  validates :lead_time_for_fulfillment, inclusion: { in: LEAD_TIME_OPTIONS }
  validates :returns_accepted, :exchanges_accepted, :refunds_accepted, :cancellations_accepted,
    inclusion: { in: [true, false] }

  validate :additional_policy_information_required_when_returns_exchanges_or_refunds_enabled
  validate :cancellation_timeframe_required_when_cancellations_enabled

  before_validation :normalize_username

  def public_tax_identifier
    "[hidden]"
  end

  private

  def normalize_username
    self.username = username.to_s.parameterize(separator: "_") if username.present?
  end

  def additional_policy_information_required_when_returns_exchanges_or_refunds_enabled
    return unless returns_accepted || exchanges_accepted || refunds_accepted
    return if additional_policy_information.present?

    errors.add(:additional_policy_information, "is required when returns, exchanges, or refunds are accepted")
  end

  def cancellation_timeframe_required_when_cancellations_enabled
    return unless cancellations_accepted
    return if cancellation_timeframe.present?

    errors.add(:cancellation_timeframe, "is required when cancellations are accepted")
  end
end


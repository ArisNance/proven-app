class MakerProfile < ApplicationRecord
  belongs_to :user

  before_validation :normalize_currency

  validates :display_name, :country, presence: true
  validates :preferred_currency, presence: true, length: { is: 3 }
  validates :bio, length: { maximum: 1_000 }, allow_blank: true
  validate :country_supported
  validate :currency_supported

  private

  def normalize_currency
    self.preferred_currency = preferred_currency.to_s.upcase if preferred_currency.present?
  end

  def country_supported
    return if country.blank?
    supported = supported_country_names
    return if supported.empty?
    return if supported.include?(country.to_s.strip.downcase)

    errors.add(:country, "must be selected from the supported countries list")
  end

  def currency_supported
    return if preferred_currency.blank?
    supported = supported_currency_codes
    return if supported.empty?
    return if supported.include?(preferred_currency.to_s.upcase)

    errors.add(:preferred_currency, "must be a supported 3-letter currency code")
  end

  def supported_country_names
    return @supported_country_names if defined?(@supported_country_names)

    names =
      if defined?(Spree::Country)
        Spree::Country.pluck(:name)
      else
        []
      end

    @supported_country_names = names.map { |name| name.to_s.downcase.strip }.uniq
  end

  def supported_currency_codes
    return @supported_currency_codes if defined?(@supported_currency_codes)

    @supported_currency_codes =
      if defined?(Money::Currency)
        Money::Currency.table.keys.map(&:to_s).map(&:upcase).uniq
      else
        []
      end
  end
end

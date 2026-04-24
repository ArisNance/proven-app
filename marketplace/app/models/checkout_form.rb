class CheckoutForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :email, :string
  attribute :first_name, :string
  attribute :last_name, :string
  attribute :phone, :string
  attribute :address1, :string
  attribute :address2, :string
  attribute :city, :string
  attribute :state, :string
  attribute :postal_code, :string
  attribute :country, :string
  attribute :shipping_notes, :string

  validates :email, :first_name, :last_name, :address1, :city, :state, :postal_code, :country, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }

  def full_name
    [first_name, last_name].join(" ").squish
  end
end

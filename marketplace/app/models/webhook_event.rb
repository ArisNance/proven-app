class WebhookEvent < ApplicationRecord
  validates :provider, :event_id, presence: true
  validates :event_id, uniqueness: { scope: :provider }

  scope :pending_processing, -> { where(processed_at: nil) }
end

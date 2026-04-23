class MakerVerification < ApplicationRecord
  enum identity_status: { pending: 0, verified: 1, failed: 2 }, _prefix: :identity
  enum workspace_status: { pending: 0, verified: 1, failed: 2 }, _prefix: :workspace
  enum production_capability_status: { pending: 0, verified: 1, failed: 2 }, _prefix: :production_capability
  enum product_origin_status: { pending: 0, verified: 1, failed: 2 }, _prefix: :product_origin
  enum workspace_type: { home_studio: 0, shared: 1, workshop: 2 }, _prefix: :workspace_type
  enum production_complexity_level: { low: 0, medium: 1, high: 2 }, _prefix: :production_complexity
  enum maker_type_classification: { fully_handmade: 0, small_batch_with_help: 1, designed_assisted_production: 2 }, _prefix: :maker_type
  enum verification_method: { live_call: 0, recorded_submission: 1, hybrid: 2 }, _prefix: :verification_method

  belongs_to :maker_application
  belongs_to :verified_by, class_name: "User", optional: true

  has_many_attached :identity_attachments
  has_many_attached :workspace_attachments
  has_many_attached :production_attachments
  has_many_attached :product_origin_attachments
  has_many_attached :reviewer_attachments

  validates :identity_name_match_confidence, :workspace_confidence, :production_confidence, :product_origin_confidence, :overall_confidence_score,
    numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 5 },
    allow_nil: true

  validates :verification_duration_minutes,
    numericality: { only_integer: true, greater_than_or_equal_to: 0 },
    allow_nil: true

  def passes?
    overall_confidence_score.to_i >= 4
  end
end


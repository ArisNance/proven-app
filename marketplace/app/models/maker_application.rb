class MakerApplication < ApplicationRecord
  HOW_LONG_OPTIONS = [
    "Less than 1 year",
    "1-3 years",
    "3-5 years",
    "5-10 years",
    "10+ years"
  ].freeze

  enum state: {
    draft: 0,
    submitted: 1,
    in_review: 2,
    accepted: 3,
    rejected: 4
  }
  enum workflow_status: {
    application_received: "application_received",
    accepted_pending_verification: "accepted_pending_verification",
    verification_under_review: "verification_under_review",
    verified: "verified"
  }, _prefix: :workflow_status

  belongs_to :user
  belongs_to :reviewer, class_name: "User", optional: true
  has_one :maker_verification, dependent: :destroy
  has_one :maker_onboarding_profile, dependent: :nullify

  validates :first_name, :last_name, :email, :business_name, :business_url, :what_do_you_make, presence: true
  validates :how_long_making, inclusion: { in: HOW_LONG_OPTIONS }, allow_blank: true
  validates :business_url,
    format: {
      with: URI::DEFAULT_PARSER.make_regexp(%w[http https]),
      message: "must be a valid URL starting with http:// or https://"
    }

  before_validation :normalize_email
  before_validation :populate_email_from_user

  def submitted?
    state.in?(%w[submitted in_review accepted rejected])
  end

  def log_communication_event!(event_type:, template:, subject:, recipient_email:, metadata: {})
    entry = {
      event_type: event_type,
      template: template,
      subject: subject,
      recipient_email: recipient_email,
      sent_at: Time.current.iso8601,
      metadata: metadata
    }

    with_lock do
      update!(communication_history: Array(communication_history) + [entry])
    end
  end

  private

  def populate_email_from_user
    self.email = user&.email if email.blank?
  end

  def normalize_email
    self.email = email.to_s.strip.downcase if email.present?
  end
end

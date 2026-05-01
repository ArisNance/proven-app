class MakerApplicationLifecycleEmailService
  def self.application_received!(maker_application)
    new(maker_application).application_received!
  end

  def self.application_accepted_schedule_verification!(maker_application)
    new(maker_application).application_accepted_schedule_verification!
  end

  def self.verification_completed!(maker_application)
    new(maker_application).verification_completed!
  end

  def self.verification_approved!(maker_application)
    new(maker_application).verification_approved!
  end

  def initialize(maker_application)
    @maker_application = maker_application
  end

  def application_received!
    send_and_track!(
      mailer_method: :application_received,
      workflow_status: :application_received,
      template_key: "maker_application_received"
    )
  end

  def application_accepted_schedule_verification!
    send_and_track!(
      mailer_method: :application_accepted_schedule_verification,
      workflow_status: :accepted_pending_verification,
      template_key: "maker_application_accepted_schedule_verification"
    )
  end

  def verification_completed!
    send_and_track!(
      mailer_method: :verification_completed,
      workflow_status: :verification_under_review,
      template_key: "maker_verification_completed"
    )
  end

  def verification_approved!
    send_and_track!(
      mailer_method: :verification_approved,
      workflow_status: :verified,
      template_key: "maker_verification_approved"
    )
  end

  private

  attr_reader :maker_application

  def send_and_track!(mailer_method:, workflow_status:, template_key:)
    message = MakerLifecycleMailer.public_send(mailer_method, maker_application).deliver_now

    maker_application.update!(workflow_status: workflow_status)
    maker_application.log_communication_event!(
      event_type: "email",
      template: template_key,
      subject: message.subject,
      recipient_email: maker_application.email,
      metadata: {
        workflow_status: workflow_status.to_s,
        mailer_method: mailer_method.to_s
      }
    )
  end
end

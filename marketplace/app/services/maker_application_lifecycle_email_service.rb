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

  def self.retry_delivery!(maker_application_id:, mailer_method:, workflow_status:, template_key:)
    maker_application = MakerApplication.find_by(id: maker_application_id)
    return false if maker_application.blank?
    return true if delivery_already_logged?(maker_application, template_key)

    new(maker_application).send(
      :send_and_track!,
      mailer_method: mailer_method.to_sym,
      workflow_status: workflow_status.to_sym,
      template_key: template_key,
      enqueue_retry: false,
      raise_on_failure: true,
      delivery_context: "sidekiq_retry"
    )
  end

  def self.delivery_already_logged?(maker_application, template_key)
    Array(maker_application.communication_history).any? do |entry|
      entry_type = entry["event_type"] || entry[:event_type]
      entry_template = entry["template"] || entry[:template]
      entry_type.to_s == "email" && entry_template.to_s == template_key.to_s
    end
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

  def send_and_track!(mailer_method:, workflow_status:, template_key:, enqueue_retry: true, raise_on_failure: false, delivery_context: "primary")
    maker_application.update!(workflow_status: workflow_status)

    message = MakerLifecycleMailer.public_send(mailer_method, maker_application)
    message.deliver_now

    maker_application.log_communication_event!(
      event_type: "email",
      template: template_key,
      subject: message.subject,
      recipient_email: maker_application.email,
      metadata: {
        workflow_status: workflow_status.to_s,
        mailer_method: mailer_method.to_s,
        delivery_status: "sent",
        delivery_context: delivery_context
      }
    )
    true
  rescue StandardError => e
    retry_job_enqueued = enqueue_retry && enqueue_retry_job(mailer_method: mailer_method, workflow_status: workflow_status, template_key: template_key)

    maker_application.log_communication_event!(
      event_type: "email_failed",
      template: template_key,
      subject: message&.subject.to_s,
      recipient_email: maker_application.email,
      metadata: {
        workflow_status: workflow_status.to_s,
        mailer_method: mailer_method.to_s,
        delivery_status: "failed",
        error_class: e.class.name,
        error_message: e.message.to_s.first(500),
        delivery_context: delivery_context,
        retry_job_enqueued: retry_job_enqueued
      }
    )

    Rails.logger.error(
      "[maker_lifecycle_email] template=#{template_key} user_id=#{maker_application.user_id} " \
      "maker_application_id=#{maker_application.id} error=#{e.class}: #{e.message}"
    )
    raise e if raise_on_failure

    false
  end

  def enqueue_retry_job(mailer_method:, workflow_status:, template_key:)
    MakerLifecycleEmailRetryJob.perform_async(
      maker_application.id,
      mailer_method.to_s,
      workflow_status.to_s,
      template_key.to_s
    )
    true
  rescue StandardError => e
    Rails.logger.error(
      "[maker_lifecycle_email_retry_enqueue] template=#{template_key} user_id=#{maker_application.user_id} " \
      "maker_application_id=#{maker_application.id} error=#{e.class}: #{e.message}"
    )
    false
  end
end

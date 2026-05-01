class MakerLifecycleEmailRetryJob
  include Sidekiq::Job
  sidekiq_options queue: :default, retry: 3

  def perform(maker_application_id, mailer_method, workflow_status, template_key)
    MakerApplicationLifecycleEmailService.retry_delivery!(
      maker_application_id: maker_application_id,
      mailer_method: mailer_method,
      workflow_status: workflow_status,
      template_key: template_key
    )
  end
end

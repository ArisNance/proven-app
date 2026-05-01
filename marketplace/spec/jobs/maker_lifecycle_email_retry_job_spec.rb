require "rails_helper"

RSpec.describe MakerLifecycleEmailRetryJob do
  it "is sidekiq job compatible" do
    expect(described_class).to include(Sidekiq::Job)
  end

  it "delegates retry delivery to the lifecycle service" do
    expect(MakerApplicationLifecycleEmailService).to receive(:retry_delivery!).with(
      maker_application_id: 42,
      mailer_method: "application_received",
      workflow_status: "application_received",
      template_key: "maker_application_received"
    )

    described_class.new.perform(42, "application_received", "application_received", "maker_application_received")
  end
end

require "rails_helper"

RSpec.describe ShippingSyncJob do
  describe "#perform" do
    it "does not raise when a duplicate webhook event is inserted concurrently" do
      allow(WebhookEvent).to receive(:exists?).and_return(false)
      allow(WebhookEvent).to receive(:create!).and_raise(ActiveRecord::RecordNotUnique, "duplicate event")
      allow(Shipstation::SyncService).to receive(:new)

      expect { described_class.new.perform({ "event" => "SHIP_NOTIFY" }) }.not_to raise_error
      expect(Shipstation::SyncService).not_to have_received(:new)
    end
  end
end

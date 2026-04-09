require "rails_helper"

RSpec.describe FeeReconciliationJob do
  it "is sidekiq job compatible" do
    expect(described_class).to include(Sidekiq::Job)
  end
end

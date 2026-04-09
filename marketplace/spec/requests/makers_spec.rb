require "rails_helper"

RSpec.describe "Maker flows", type: :request do
  it "requires auth for onboarding" do
    get "/makers/onboarding"
    expect(response).to have_http_status(:found)
  end
end

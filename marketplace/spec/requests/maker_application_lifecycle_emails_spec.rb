require "rails_helper"

RSpec.describe "Maker application lifecycle emails", type: :request do
  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    ActionMailer::Base.deliveries.clear
    example.run
  ensure
    ActionController::Base.allow_forgery_protection = original
    ActionMailer::Base.deliveries.clear
  end

  let(:password) { "password123" }

  def maker_application_attributes(email:, first_name: "Mia")
    {
      first_name: first_name,
      last_name: "Parker",
      email: email,
      business_name: "Mia Studio",
      business_url: "https://example.com/mia-studio",
      what_do_you_make: "Handmade ceramics",
      how_long_making: "3-5 years"
    }
  end

  def sign_in_user!(email:, password:)
    post user_session_path, params: { user: { email: email, password: password } }
    expect(response).to have_http_status(:found)
  end

  def sign_in_admin!
    post admin_login_path, params: {
      username: Admin::SessionsController::ADMIN_USERNAME,
      password: Admin::SessionsController::ADMIN_PASSWORD
    }
    expect(response).to redirect_to(admin_root_path)
  end

  it "sends application received email after maker submission" do
    user = User.create!(email: "maker-submission@example.com", password: password, role: :buyer)
    sign_in_user!(email: user.email, password: password)

    expect do
      post makers_onboarding_path, params: {
        maker_application: maker_application_attributes(email: user.email, first_name: "Mia")
      }
    end.to change(MakerApplication, :count).by(1)

    expect(response).to redirect_to(dashboard_index_path)

    maker_application = MakerApplication.last
    expect(maker_application.workflow_status).to eq("application_received")
    expect(maker_application.communication_history.size).to eq(1)
    expect(maker_application.communication_history.last["template"]).to eq("maker_application_received")

    mail = ActionMailer::Base.deliveries.last
    expect(mail.subject).to eq("Maker application received")
    expect(mail.to).to eq([user.email])
    expect(mail.from).to eq(Array(ApplicationMailer.default_params[:from]))
    expect(mail.body.encoded).to include("Hi Mia")
  end

  it "sends accepted + scheduling email when admin accepts application" do
    User.create!(email: "admin-accept@example.com", password: password, role: :admin)
    user = User.create!(email: "maker-accepted@example.com", password: password, role: :buyer)
    maker_application = user.create_maker_application!(
      maker_application_attributes(email: user.email, first_name: "Olivia").merge(state: :submitted, submitted_at: Time.current)
    )

    sign_in_admin!

    post accept_admin_maker_application_path(maker_application)
    expect(response).to redirect_to(admin_maker_application_path(maker_application))

    maker_application.reload
    expect(maker_application.state).to eq("accepted")
    expect(maker_application.workflow_status).to eq("accepted_pending_verification")
    expect(maker_application.communication_history.size).to eq(1)
    expect(maker_application.communication_history.last["template"]).to eq("maker_application_accepted_schedule_verification")

    mail = ActionMailer::Base.deliveries.last
    expect(mail.subject).to eq("Your maker application was accepted - schedule verification")
    expect(mail.to).to eq([user.email])
    expect(mail.body.encoded).to include("https://calendly.com/emily-proven/30min")
    expect(mail.body.encoded).to include("Hi Olivia")
  end

  it "sends verification completed email when admin marks verification complete" do
    admin_user = User.create!(email: "admin-complete@example.com", password: password, role: :admin)
    user = User.create!(email: "maker-complete@example.com", password: password, role: :buyer)
    maker_application = user.create_maker_application!(
      maker_application_attributes(email: user.email, first_name: "Noah").merge(
        state: :accepted,
        workflow_status: :accepted_pending_verification,
        submitted_at: Time.current
      )
    )

    sign_in_admin!

    post complete_verification_admin_maker_application_path(maker_application)
    expect(response).to redirect_to(admin_maker_application_path(maker_application))

    maker_application.reload
    expect(maker_application.workflow_status).to eq("verification_under_review")
    expect(maker_application.communication_history.size).to eq(1)
    expect(maker_application.communication_history.last["template"]).to eq("maker_verification_completed")

    verification = maker_application.maker_verification
    expect(verification).to be_present
    expect(verification.verified_by).to eq(admin_user)

    mail = ActionMailer::Base.deliveries.last
    expect(mail.subject).to eq("Verification completed")
    expect(mail.to).to eq([user.email])
    expect(mail.body.encoded).to include("Hi Noah")
  end

  it "sends verification approved email when admin approves verification" do
    User.create!(email: "admin-approved@example.com", password: password, role: :admin)
    user = User.create!(email: "maker-approved@example.com", password: password, role: :buyer)
    maker_application = user.create_maker_application!(
      maker_application_attributes(email: user.email, first_name: "Ava").merge(
        state: :accepted,
        workflow_status: :verification_under_review,
        submitted_at: Time.current
      )
    )
    maker_application.create_maker_verification!(overall_confidence_score: 5, verification_method: :live_call)

    sign_in_admin!

    post approve_admin_maker_application_path(maker_application)
    expect(response).to redirect_to(admin_maker_application_path(maker_application))

    maker_application.reload
    expect(maker_application.workflow_status).to eq("verified")
    expect(maker_application.communication_history.size).to eq(1)
    expect(maker_application.communication_history.last["template"]).to eq("maker_verification_approved")
    expect(user.reload.role).to eq("maker")

    mail = ActionMailer::Base.deliveries.last
    expect(mail.subject).to eq("Verification approved")
    expect(mail.to).to eq([user.email])
    expect(mail.body.encoded).to include("Hi Ava")
  end

  it "does not 500 onboarding when email delivery fails" do
    user = User.create!(email: "maker-email-failure@example.com", password: password, role: :buyer)
    sign_in_user!(email: user.email, password: password)
    allow(MakerLifecycleEmailRetryJob).to receive(:perform_async).and_return("retry-jid-123")
    allow_any_instance_of(ActionMailer::MessageDelivery).to receive(:deliver_now).and_raise(StandardError, "Resend outage")

    post makers_onboarding_path, params: {
      maker_application: maker_application_attributes(email: user.email, first_name: "Liam")
    }

    expect(response).to redirect_to(dashboard_index_path)

    maker_application = user.reload.maker_application
    expect(maker_application.workflow_status).to eq("application_received")
    expect(maker_application.communication_history.size).to eq(1)
    expect(maker_application.communication_history.last["event_type"]).to eq("email_failed")
    expect(maker_application.communication_history.last["template"]).to eq("maker_application_received")
    expect(maker_application.communication_history.last.dig("metadata", "delivery_status")).to eq("failed")
    expect(maker_application.communication_history.last.dig("metadata", "retry_job_enqueued")).to eq(true)
    expect(MakerLifecycleEmailRetryJob).to have_received(:perform_async).with(
      maker_application.id,
      "application_received",
      "application_received",
      "maker_application_received"
    )
  end
end

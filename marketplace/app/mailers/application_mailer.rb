class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("RESEND_FROM_EMAIL", Rails.env.production? ? "noreply@shopproven.com" : "onboarding@resend.dev")
  layout "mailer"
end

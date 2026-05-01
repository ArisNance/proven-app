class ApplicationMailer < ActionMailer::Base
  default from: Rails.env.production? ? "noreply@shopproven.com" : "onboarding@resend.dev"
  layout "mailer"
end

class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("RESEND_FROM_EMAIL", "no-reply@example.com")
  layout "mailer"
end

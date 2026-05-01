class MakerLifecycleMailer < ApplicationMailer
  SCHEDULING_LINK = "https://calendly.com/emily-proven/30min".freeze

  def application_received(maker_application)
    @first_name = maker_application.first_name

    mail(
      to: maker_application.email,
      subject: "Maker application received"
    )
  end

  def application_accepted_schedule_verification(maker_application)
    @first_name = maker_application.first_name
    @scheduling_link = SCHEDULING_LINK

    mail(
      to: maker_application.email,
      subject: "Your maker application was accepted - schedule verification"
    )
  end

  def verification_completed(maker_application)
    @first_name = maker_application.first_name

    mail(
      to: maker_application.email,
      subject: "Verification completed"
    )
  end

  def verification_approved(maker_application)
    @first_name = maker_application.first_name

    mail(
      to: maker_application.email,
      subject: "Verification approved"
    )
  end
end

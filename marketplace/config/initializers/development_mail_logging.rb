if Rails.env.development?
  class DevelopmentMailLogger
    def self.delivered_email(message)
      preview = message.body.to_s.gsub(/\s+/, " ").strip.first(300)

      Rails.logger.info(
        "[MAIL_DUMMY] to=#{Array(message.to).join(',')} subject=#{message.subject.inspect} " \
        "from=#{Array(message.from).join(',')} body_preview=#{preview.inspect}"
      )
    end
  end

  ActionMailer::Base.register_observer(DevelopmentMailLogger)
end

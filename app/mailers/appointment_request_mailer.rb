class AppointmentRequestMailer < ApplicationMailer
  def request_answered(appointment_request, reason: nil)
    @request      = appointment_request
    @nutritionist = appointment_request.nutritionist
    @service      = appointment_request.service
    @reason       = reason || (@request.accepted? ? :accepted : :rejected)
    @custom_note  = @request.rejection_note.presence

    I18n.with_locale(I18n.default_locale) do
      @body = I18n.t("mailer.messages.#{@reason}.body")
      mail(subject: I18n.t("mailer.messages.#{@reason}.subject"), to: @request.guest_email)
    end
  end
end

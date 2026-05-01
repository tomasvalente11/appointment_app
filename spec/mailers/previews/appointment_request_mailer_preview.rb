# Preview all emails at http://localhost:3000/rails/mailers/appointment_request_mailer
class AppointmentRequestMailerPreview < ActionMailer::Preview

  # Preview this email at http://localhost:3000/rails/mailers/appointment_request_mailer/request_answered
  def request_answered
    AppointmentRequestMailer.request_answered
  end

end

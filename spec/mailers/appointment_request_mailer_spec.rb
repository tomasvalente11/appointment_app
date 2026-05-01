require "rails_helper"

RSpec.describe AppointmentRequestMailer, type: :mailer do
  let(:nutritionist)        { create(:nutritionist, name: "Ana Costa") }
  let(:service)             { create(:service, location: "Braga", name: "First Appointment", nutritionist: nutritionist) }
  let(:appointment_request) { create(:appointment_request, guest_email: "guest@example.com", guest_name: "João Silva", nutritionist: nutritionist, service: service) }

  describe "#request_answered — accepted" do
    before { appointment_request.accepted! }

    let(:mail) { AppointmentRequestMailer.request_answered(appointment_request) }

    it "sends to the guest email" do
      expect(mail.to).to eq(["guest@example.com"])
    end

    it "has the confirmed subject" do
      expect(mail.subject).to eq("Your appointment was confirmed!")
    end

    it "includes the nutritionist name in the body" do
      expect(mail.html_part.body.to_s).to include("Ana Costa")
      expect(mail.text_part.body.to_s).to include("Ana Costa")
    end

    it "includes the service and location in the body" do
      expect(mail.html_part.body.to_s).to include("First Appointment")
      expect(mail.html_part.body.to_s).to include("Braga")
    end
  end

  describe "#request_answered — rejected" do
    before { appointment_request.rejected! }

    let(:mail) { AppointmentRequestMailer.request_answered(appointment_request) }

    it "has the update subject" do
      expect(mail.subject).to eq("Update on your appointment request")
    end

    it "includes a rejection message in the body" do
      expect(mail.html_part.body.to_s).to include("not accepted")
      expect(mail.text_part.body.to_s).to include("not accepted")
    end
  end
end

require 'rails_helper'

RSpec.describe AppointmentRequestService do
  let(:nutritionist) { create(:nutritionist) }
  let(:service)      { create(:service, nutritionist: nutritionist) }
  let(:base_params) do
    {
      guest_email:     "guest@example.com",
      guest_name:      "Test Guest",
      nutritionist_id: nutritionist.id,
      requested_at:    1.week.from_now.change(hour: 10, min: 0, sec: 0),
      service_id:      service.id
    }
  end

  describe ".create" do
    it "returns a persisted request with valid params" do
      result = AppointmentRequestService.create(base_params)
      expect(result).to be_persisted
      expect(result.status).to eq("pending")
    end

    it "returns an unpersisted request with errors on invalid params" do
      result = AppointmentRequestService.create(base_params.merge(guest_email: "bad"))
      expect(result).not_to be_persisted
      expect(result.errors).to be_present
    end

    it "rejects all existing pending requests from the same email" do
      existing = create(:appointment_request, guest_email: "guest@example.com", nutritionist: nutritionist)
      AppointmentRequestService.create(base_params)
      expect(existing.reload).to be_rejected
    end

    it "enqueues a rejection mailer for each invalidated request" do
      create(:appointment_request, guest_email: "guest@example.com", nutritionist: nutritionist)
      expect {
        AppointmentRequestService.create(base_params)
      }.to have_enqueued_mail(AppointmentRequestMailer, :request_answered)
    end

    it "does not affect pending requests from a different email" do
      other = create(:appointment_request, guest_email: "other@example.com", nutritionist: nutritionist)
      AppointmentRequestService.create(base_params)
      expect(other.reload).to be_pending
    end

    it "rolls back invalidations if the new request is invalid" do
      existing = create(:appointment_request, guest_email: "guest@example.com", nutritionist: nutritionist)
      AppointmentRequestService.create(base_params.merge(guest_name: ""))
      expect(existing.reload).to be_pending
    end
  end

  describe ".accept!" do
    let(:requested_at) { 1.week.from_now.change(hour: 10, min: 0, sec: 0) }
    let(:request) do
      create(:appointment_request, guest_email: "other@example.com", nutritionist: nutritionist,
             requested_at: requested_at, service: service)
    end

    it "sets status to accepted" do
      AppointmentRequestService.accept!(request)
      expect(request.reload).to be_accepted
    end

    it "enqueues a confirmation mailer for the accepted request" do
      expect {
        AppointmentRequestService.accept!(request)
      }.to have_enqueued_mail(AppointmentRequestMailer, :request_answered)
    end

    it "rejects pending requests that overlap the accepted slot" do
      overlapping = create(:appointment_request, nutritionist: nutritionist,
                           requested_at: requested_at, service: service)
      AppointmentRequestService.accept!(request)
      expect(overlapping.reload).to be_rejected
    end

    it "does not reject requests outside the service duration window" do
      outside = create(:appointment_request, nutritionist: nutritionist,
                       requested_at: requested_at + 2.hours, service: service)
      AppointmentRequestService.accept!(request)
      expect(outside.reload).to be_pending
    end

    it "does not affect requests for a different nutritionist" do
      other_nutritionist = create(:nutritionist)
      other_request = create(:appointment_request, nutritionist: other_nutritionist,
                             requested_at: requested_at)
      AppointmentRequestService.accept!(request)
      expect(other_request.reload).to be_pending
    end
  end

  describe ".reject!" do
    let(:request) { create(:appointment_request, nutritionist: nutritionist) }

    it "sets status to rejected" do
      AppointmentRequestService.reject!(request)
      expect(request.reload).to be_rejected
    end

    it "stores the rejection note" do
      AppointmentRequestService.reject!(request, rejection_note: "No slots available")
      expect(request.reload.rejection_note).to eq("No slots available")
    end

    it "enqueues a rejection mailer" do
      expect {
        AppointmentRequestService.reject!(request)
      }.to have_enqueued_mail(AppointmentRequestMailer, :request_answered)
    end
  end
end

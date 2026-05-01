require 'rails_helper'

RSpec.describe "Api::AppointmentRequests", type: :request do
  let(:nutritionist) { create(:nutritionist) }
  let(:service)      { create(:service, nutritionist: nutritionist) }

  describe "POST /api/appointment_requests" do
    let(:valid_params) do
      {
        appointment_request: {
          guest_email:    "guest@example.com",
          guest_name:     "Test Guest",
          nutritionist_id: nutritionist.id,
          requested_at:   1.week.from_now.iso8601,
          service_id:     service.id,
        },
      }
    end

    it "creates a pending appointment request" do
      expect {
        post "/api/appointment_requests", params: valid_params, as: :json
      }.to change(AppointmentRequest, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["status"]).to eq("pending")
    end

    it "invalidates a previous pending request from the same email" do
      existing = create(:appointment_request, guest_email: "guest@example.com", nutritionist: nutritionist)

      post "/api/appointment_requests", params: valid_params, as: :json

      expect(existing.reload).to be_rejected
    end

    it "returns unprocessable_entity with invalid params" do
      post "/api/appointment_requests",
        params: { appointment_request: { guest_email: "bad", guest_name: "", nutritionist_id: nutritionist.id } },
        as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["errors"]).to be_present
    end
  end

  describe "PATCH /api/appointment_requests/:id" do
    let(:appointment_request) { create(:appointment_request, nutritionist: nutritionist, service: service) }

    it "accepts the request and enqueues the mailer" do
      expect {
        patch "/api/appointment_requests/#{appointment_request.id}",
          params: { appointment_request: { nutritionist_id: nutritionist.id, status: "accepted" } },
          as: :json
      }.to have_enqueued_mail(AppointmentRequestMailer, :request_answered)

      expect(appointment_request.reload).to be_accepted
      expect(response).to have_http_status(:ok)
    end

    it "rejects the request and enqueues the mailer" do
      expect {
        patch "/api/appointment_requests/#{appointment_request.id}",
          params: { appointment_request: { nutritionist_id: nutritionist.id, status: "rejected" } },
          as: :json
      }.to have_enqueued_mail(AppointmentRequestMailer, :request_answered)

      expect(appointment_request.reload).to be_rejected
    end

    it "rejects overlapping pending requests when accepting" do
      overlapping = create(:appointment_request,
        guest_email: "other@example.com",
        nutritionist: nutritionist,
        requested_at: appointment_request.requested_at,
        service: service,
      )

      patch "/api/appointment_requests/#{appointment_request.id}",
        params: { appointment_request: { nutritionist_id: nutritionist.id, status: "accepted" } },
        as: :json

      expect(overlapping.reload).to be_rejected
    end

    it "returns forbidden when nutritionist_id does not match" do
      other = create(:nutritionist)

      patch "/api/appointment_requests/#{appointment_request.id}",
        params: { appointment_request: { nutritionist_id: other.id, status: "accepted" } },
        as: :json

      expect(response).to have_http_status(:forbidden)
    end
  end
end

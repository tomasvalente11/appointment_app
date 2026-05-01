require 'rails_helper'

RSpec.describe "Api::Nutritionists", type: :request do
  let(:nutritionist) { create(:nutritionist) }
  let(:service)      { create(:service, nutritionist: nutritionist) }
  let!(:appointment_request) do
    create(:appointment_request, nutritionist: nutritionist, service: service)
  end

  describe "GET /api/nutritionists/:nutritionist_id/appointment_requests" do
    it "returns all requests for the nutritionist as JSON" do
      get "/api/nutritionists/#{nutritionist.id}/appointment_requests", as: :json

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body).to be_an(Array)
      expect(body.size).to eq(1)
    end

    it "includes the expected fields" do
      get "/api/nutritionists/#{nutritionist.id}/appointment_requests", as: :json

      record = response.parsed_body.first
      expect(record.keys).to match_array(%w[guest_email guest_name id nutritionist_id rejection_note requested_at service status])
    end

    it "includes nested service name and location" do
      get "/api/nutritionists/#{nutritionist.id}/appointment_requests", as: :json

      service_data = response.parsed_body.first["service"]
      expect(service_data.keys).to match_array(%w[location name])
    end
  end
end

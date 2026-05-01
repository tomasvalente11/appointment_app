require 'rails_helper'

RSpec.describe "Api::Nutritionists available dates and slots", type: :request do
  let(:nutritionist) { create(:nutritionist) }
  let!(:monday_slot) do
    create(:availability_slot, nutritionist: nutritionist, day_of_week: 1,
           start_time: "09:00", end_time: "11:00")
  end

  describe "GET /api/nutritionists/:id/available_dates" do
    it "returns upcoming dates matching the nutritionist's working days" do
      get available_dates_api_nutritionist_path(nutritionist), as: :json

      expect(response).to have_http_status(:ok)
      dates = response.parsed_body["available_dates"]
      expect(dates).to be_an(Array)
      expect(dates).not_to be_empty
      dates.each do |d|
        expect(Date.parse(d).wday).to eq(1)
      end
    end

    it "returns an empty list when no availability is configured" do
      nutritionist_without_slots = create(:nutritionist, name: "No Slots")
      get available_dates_api_nutritionist_path(nutritionist_without_slots), as: :json

      expect(response.parsed_body["available_dates"]).to eq([])
    end

    it "returns 60 upcoming dates" do
      get available_dates_api_nutritionist_path(nutritionist), as: :json

      expect(response.parsed_body["available_dates"].size).to eq(60)
    end
  end

  describe "GET /api/nutritionists/:id/available_slots" do
    let(:next_monday) { Date.today.next_occurring(:monday).to_s }

    it "returns time slots for a working day" do
      get available_slots_api_nutritionist_path(nutritionist), params: { date: next_monday }, as: :json

      expect(response).to have_http_status(:ok)
      slots = response.parsed_body["slots"]
      expect(slots).to include("09:00", "10:00")
    end

    it "returns an empty array for a non-working day" do
      next_sunday = Date.today.next_occurring(:sunday).to_s
      get available_slots_api_nutritionist_path(nutritionist), params: { date: next_sunday }, as: :json

      expect(response.parsed_body["slots"]).to eq([])
    end

    it "respects service duration when provided" do
      service = create(:service, nutritionist: nutritionist, duration: 30)
      get available_slots_api_nutritionist_path(nutritionist),
          params: { date: next_monday, service_id: service.id }, as: :json

      slots = response.parsed_body["slots"]
      expect(slots).to include("09:00", "09:30", "10:00", "10:30")
    end

    it "excludes already-booked slots" do
      service = create(:service, nutritionist: nutritionist, duration: 60)
      create(:appointment_request,
             nutritionist: nutritionist,
             service: service,
             status: :accepted,
             requested_at: Time.zone.parse("#{next_monday} 09:00"))

      get available_slots_api_nutritionist_path(nutritionist),
          params: { date: next_monday, service_id: service.id }, as: :json

      expect(response.parsed_body["slots"]).not_to include("09:00")
      expect(response.parsed_body["slots"]).to include("10:00")
    end

    it "blocks every slot that overlaps with a longer booking" do
      monday_slot.update!(end_time: "13:00")
      long_service  = create(:service, nutritionist: nutritionist, name: "Long",  duration: 90)
      short_service = create(:service, nutritionist: nutritionist, name: "Short", duration: 60)

      create(:appointment_request,
             nutritionist: nutritionist,
             service: long_service,
             status: :accepted,
             requested_at: Time.zone.parse("#{next_monday} 09:00"))

      get available_slots_api_nutritionist_path(nutritionist),
          params: { date: next_monday, service_id: short_service.id }, as: :json

      slots = response.parsed_body["slots"]
      expect(slots).not_to include("09:00", "10:00")
      expect(slots).to include("11:00", "12:00")
    end
  end
end

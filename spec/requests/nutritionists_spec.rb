require 'rails_helper'

RSpec.describe "Nutritionists", type: :request do
  describe "GET / (landing)" do
    it "returns http success" do
      get root_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /find (index)" do
    let!(:braga_nutritionist) do
      n = create(:nutritionist, name: "Ana Braga")
      create(:service, nutritionist: n, location: "Braga", latitude: 41.5513, longitude: -8.4205)
      n
    end

    let!(:porto_nutritionist) do
      n = create(:nutritionist, name: "Bruno Porto")
      create(:service, :porto, nutritionist: n)
      n
    end

    it "returns all nutritionists when no filters given" do
      get find_nutritionists_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Ana Braga", "Bruno Porto")
    end

    it "filters by location within radius" do
      get find_nutritionists_path, params: { location: "Braga", radius: 25 }
      expect(response.body).to include("Ana Braga")
      expect(response.body).not_to include("Bruno Porto")
    end

    it "includes nutritionists within a wider radius" do
      get find_nutritionists_path, params: { location: "Braga", radius: 100 }
      expect(response.body).to include("Ana Braga")
    end

    it "returns JSON for the appointment modal search" do
      get find_nutritionists_path, params: { q: "Ana", format: :json }
      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body).to be_an(Array)
      expect(body.map { |n| n["name"] }).to include("Ana Braga")
    end

    it "falls back to Braga when location cannot be geocoded" do
      Geocoder::Lookup::Test.add_stub("Unknown City XYZ", [])
      get find_nutritionists_path, params: { location: "Unknown City XYZ", radius: 25 }
      # Invalid location defaults to Braga — results are shown ordered by distance from Braga
      expect(response.body).to include("Ana Braga")
    end
  end

  describe "GET /nutritionists/:id/requests" do
    let(:nutritionist) { create(:nutritionist) }

    it "returns the requests page" do
      get requests_nutritionist_path(nutritionist)
      expect(response).to have_http_status(:ok)
    end
  end
end

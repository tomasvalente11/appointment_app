require 'rails_helper'

RSpec.describe Nutritionist, type: :model do
  describe "validations" do
    it "requires name" do
      expect(build(:nutritionist, name: nil)).not_to be_valid
    end
  end

  describe ".search_by_term" do
    let!(:nutritionist) { create(:nutritionist, name: "Ana Costa") }
    let!(:service)      { create(:service, name: "Sports Nutrition", nutritionist: nutritionist) }
    let!(:other)        { create(:nutritionist, name: "Bruno Ferreira") }
    let!(:other_service){ create(:service, name: "Follow-up", nutritionist: other) }

    it "returns nutritionists matching by name" do
      expect(Nutritionist.search_by_term("Ana")).to include(nutritionist)
      expect(Nutritionist.search_by_term("Ana")).not_to include(other)
    end

    it "returns nutritionists matching by service name" do
      expect(Nutritionist.search_by_term("Sports")).to include(nutritionist)
      expect(Nutritionist.search_by_term("Sports")).not_to include(other)
    end

    it "is case-insensitive" do
      expect(Nutritionist.search_by_term("ana")).to include(nutritionist)
      expect(Nutritionist.search_by_term("sports nutrition")).to include(nutritionist)
    end
  end

  describe ".nearest_to" do
    let!(:braga_nutritionist) { create(:nutritionist, name: "Braga One") }
    let!(:porto_nutritionist) { create(:nutritionist, name: "Porto One") }
    let!(:braga_service) { create(:service, nutritionist: braga_nutritionist, latitude: 41.5513, longitude: -8.4205) }
    let!(:porto_service) { create(:service, :porto, nutritionist: porto_nutritionist) }

    it "orders by proximity to given coordinates" do
      braga_coords = [41.5513, -8.4205]
      results = Nutritionist.nearest_to(*braga_coords)

      expect(results.first).to eq(braga_nutritionist)
    end

    it "excludes nutritionists without geocoded services" do
      ungeocode = create(:nutritionist, name: "No Location")
      create(:service, nutritionist: ungeocode, latitude: nil, longitude: nil)

      results = Nutritionist.nearest_to(41.5513, -8.4205)
      expect(results).not_to include(ungeocode)
    end
  end

  describe ".available_on" do
    let!(:nutritionist) { create(:nutritionist) }
    let!(:other)        { create(:nutritionist) }

    it "returns nutritionists with a slot on the given day of week" do
      date = Date.today.next_occurring(:monday)
      create(:availability_slot, nutritionist: nutritionist, day_of_week: date.wday)

      expect(Nutritionist.available_on(date)).to include(nutritionist)
      expect(Nutritionist.available_on(date)).not_to include(other)
    end
  end
end

require 'rails_helper'

RSpec.describe AvailabilitySlot, type: :model do
  let(:nutritionist) { create(:nutritionist) }

  describe "validations" do
    it "is valid with valid attributes" do
      expect(build(:availability_slot, nutritionist: nutritionist)).to be_valid
    end

    it "requires start_time" do
      expect(build(:availability_slot, nutritionist: nutritionist, start_time: nil)).not_to be_valid
    end

    it "requires end_time" do
      expect(build(:availability_slot, nutritionist: nutritionist, end_time: nil)).not_to be_valid
    end

    it "requires day_of_week to be between 0 and 6" do
      expect(build(:availability_slot, nutritionist: nutritionist, day_of_week: 7)).not_to be_valid
      expect(build(:availability_slot, nutritionist: nutritionist, day_of_week: -1)).not_to be_valid
    end

    it "enforces uniqueness of day_of_week per nutritionist" do
      create(:availability_slot, nutritionist: nutritionist, day_of_week: 1)
      expect(build(:availability_slot, nutritionist: nutritionist, day_of_week: 1)).not_to be_valid
    end

    it "allows the same day_of_week for different nutritionists" do
      other = create(:nutritionist, name: "Other")
      create(:availability_slot, nutritionist: nutritionist, day_of_week: 1)
      expect(build(:availability_slot, nutritionist: other, day_of_week: 1)).to be_valid
    end

    it "is invalid when end_time is before start_time" do
      slot = build(:availability_slot, nutritionist: nutritionist, start_time: "17:00", end_time: "09:00")
      expect(slot).not_to be_valid
      expect(slot.errors[:end_time]).to be_present
    end
  end

  describe "#open_slots_on" do
    let(:slot) { create(:availability_slot, nutritionist: nutritionist, start_time: "09:00", end_time: "11:00") }
    let(:date) { Date.today.next_occurring(:monday) }

    it "returns time slots spaced by duration" do
      slots = slot.open_slots_on(date, 60)
      expect(slots.size).to eq(2)
      expect(slots.map { |t| t.strftime("%H:%M") }).to eq(["09:00", "10:00"])
    end

    it "does not include a slot that would run past end_time" do
      slots = slot.open_slots_on(date, 60)
      expect(slots.map { |t| t.strftime("%H:%M") }).not_to include("11:00")
    end

    it "returns correct slots for 30-minute duration" do
      slots = slot.open_slots_on(date, 30)
      expect(slots.map { |t| t.strftime("%H:%M") }).to eq(["09:00", "09:30", "10:00", "10:30"])
    end

    it "returns an empty array when duration exceeds the window" do
      slot = create(:availability_slot, nutritionist: create(:nutritionist, name: "Short"),
                    start_time: "09:00", end_time: "09:30")
      expect(slot.open_slots_on(date, 60)).to be_empty
    end
  end
end

require 'rails_helper'

RSpec.describe AppointmentRequest, type: :model do
  let(:nutritionist) { create(:nutritionist) }
  let(:service)      { create(:service, nutritionist: nutritionist) }

  describe "validations" do
    it "is valid with valid attributes" do
      expect(build(:appointment_request, nutritionist: nutritionist)).to be_valid
    end

    it "requires guest_email" do
      expect(build(:appointment_request, guest_email: nil, nutritionist: nutritionist)).not_to be_valid
    end

    it "requires guest_name" do
      expect(build(:appointment_request, guest_name: nil, nutritionist: nutritionist)).not_to be_valid
    end

    it "requires requested_at" do
      expect(build(:appointment_request, nutritionist: nutritionist, requested_at: nil)).not_to be_valid
    end

    it "rejects a malformed email" do
      expect(build(:appointment_request, guest_email: "not-an-email", nutritionist: nutritionist)).not_to be_valid
    end

    it "rejects a duplicate pending request for the same guest, nutritionist, and time" do
      create(:appointment_request, guest_email: "guest@example.com", nutritionist: nutritionist, requested_at: 1.week.from_now.change(hour: 10))
      duplicate = build(:appointment_request, guest_email: "guest@example.com", nutritionist: nutritionist, requested_at: 1.week.from_now.change(hour: 10))
      expect(duplicate).not_to be_valid
    end
  end

  describe "enum status" do
    it "defaults to pending" do
      expect(AppointmentRequest.new.status).to eq("pending")
    end

    it "accepts accepted and rejected values" do
      request = create(:appointment_request, nutritionist: nutritionist)
      request.accepted!
      expect(request.reload).to be_accepted
      request.rejected!
      expect(request.reload).to be_rejected
    end
  end
end

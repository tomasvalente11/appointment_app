require 'rails_helper'

RSpec.describe "Booking flow", type: :system do
  let!(:nutritionist) do
    n = create(:nutritionist, name: "Ana Costa")
    create(:service, nutritionist: n, name: "First Appointment", duration: 60,
           location: "Braga", latitude: 41.5513, longitude: -8.4205)
    create(:availability_slot, nutritionist: n, day_of_week: 1,
           start_time: "09:00", end_time: "17:00")
    n
  end

  it "guest can open the scheduling modal from a nutritionist card" do
    visit find_nutritionists_path

    expect(page).to have_content("Ana Costa")

    click_button I18n.t("nutritionists.results.schedule_btn")

    expect(page).to have_content(I18n.t("modal.heading"))
    expect(find("[data-appointment-modal-target='nutritionistSearch']").value).to eq("Ana Costa")
    expect(find("[data-appointment-modal-target='nutritionistSearch']")[:readonly]).to eq("true")
  end

  it "guest can complete the full booking and see success screen" do
    visit find_nutritionists_path
    click_button I18n.t("nutritionists.results.schedule_btn")

    click_button I18n.t("modal.btn_next")

    next_monday = Date.today.next_occurring(:monday)
    find("[data-appointment-modal-target='dateInput']").set(next_monday.strftime("%Y-%m-%d"))
    find("[data-appointment-modal-target='dateInput']").send_keys(:tab)

    expect(page).to have_css("[data-appointment-modal-target='timeSlots'] button", wait: 5)
    find("[data-appointment-modal-target='timeSlots'] button", match: :first).click

    click_button I18n.t("modal.btn_next")

    fill_in I18n.t("modal.label_name").delete(":"), with: "João Silva"
    fill_in I18n.t("modal.label_email").delete(":"), with: "joao@example.com"

    click_button I18n.t("modal.btn_confirm")

    expect(page).to have_content(I18n.t("modal.success_heading"), wait: 5)
    expect(AppointmentRequest.last.guest_name).to eq("João Silva")
  end
end

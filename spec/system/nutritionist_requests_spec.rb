require 'rails_helper'

RSpec.describe "Nutritionist request management", type: :system do
  let!(:nutritionist) { create(:nutritionist, name: "Ana Costa") }
  let!(:service) { create(:service, nutritionist: nutritionist) }
  let!(:pending_request) do
    create(:appointment_request, nutritionist: nutritionist, service: service,
           guest_name: "João Silva", guest_email: "joao@example.com")
  end

  before { visit requests_nutritionist_path(nutritionist) }

  it "displays pending requests" do
    expect(page).to have_content("João Silva")
  end

  it "reveals accept/reject buttons after clicking Answer request" do
    click_button I18n.t("requests.action.answer_request")

    expect(page).to have_button(I18n.t("requests.action.accept"))
    expect(page).to have_button(I18n.t("requests.action.reject"))
  end

  it "accepts a request and shows accepted badge" do
    click_button I18n.t("requests.action.answer_request")
    click_button I18n.t("requests.action.accept")

    expect(page).to have_content(I18n.t("requests.status.accepted"), wait: 5)
    expect(pending_request.reload).to be_accepted
  end

  it "rejects a request via the rejection modal" do
    click_button I18n.t("requests.action.answer_request")
    click_button I18n.t("requests.action.reject")

    expect(page).to have_content(I18n.t("requests.action.reject_heading"), wait: 3)

    fill_in I18n.t("requests.action.reject_placeholder"), with: "Not available"
    click_button I18n.t("requests.action.confirm_rejection")

    expect(page).to have_content(I18n.t("requests.status.rejected"), wait: 5)
    expect(pending_request.reload).to be_rejected
    expect(pending_request.reload.rejection_note).to eq("Not available")
  end
end

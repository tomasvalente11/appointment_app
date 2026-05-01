class AppointmentRequest < ApplicationRecord
  # associations
  belongs_to :nutritionist
  belongs_to :service, optional: true

  # validations
  validates :guest_email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :guest_email, :guest_name, :requested_at, presence: true
  validate :no_duplicate_pending_request

  enum :status, { accepted: "accepted", pending: "pending", rejected: "rejected" }, default: "pending"

  private

  def no_duplicate_pending_request
    return unless guest_email.present? && nutritionist_id.present? && requested_at.present?

    duplicate = AppointmentRequest
      .where(guest_email: guest_email, nutritionist_id: nutritionist_id, requested_at: requested_at, status: :pending)
      .where.not(id: id)
      .exists?

    errors.add(:base, :duplicate_pending_request) if duplicate
  end
end

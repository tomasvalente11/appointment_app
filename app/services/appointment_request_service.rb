class AppointmentRequestService
  def self.create(params)
    request = AppointmentRequest.new(params)
    ApplicationRecord.transaction do
      invalidate_previous_pending(request.guest_email)
      raise ActiveRecord::Rollback unless request.save
    end
    request
  end

  def self.accept!(request)
    ApplicationRecord.transaction do
      Nutritionist.lock.find(request.nutritionist_id)
      request.update!(status: :accepted)
      reject_overlapping(request)
    end
    AppointmentRequestMailer.request_answered(request).deliver_later
    request
  end

  def self.reject!(request, rejection_note: nil)
    request.update!(status: :rejected, rejection_note: rejection_note)
    AppointmentRequestMailer.request_answered(request).deliver_later
    request
  end

  class << self
    private

    def invalidate_previous_pending(guest_email)
      AppointmentRequest.where(guest_email: guest_email, status: :pending).each do |r|
        r.update!(status: :rejected)
        AppointmentRequestMailer.request_answered(r, reason: :invalidated).deliver_later
      end
    end

    def reject_overlapping(request)
      end_time = request.requested_at + (request.service&.duration || 60).minutes
      AppointmentRequest
        .where(nutritionist_id: request.nutritionist_id, status: :pending)
        .where.not(id: request.id)
        .where(requested_at: request.requested_at...end_time)
        .each do |r|
          r.update!(status: :rejected)
          AppointmentRequestMailer.request_answered(r, reason: :slot_taken).deliver_later
        end
    end
  end
end

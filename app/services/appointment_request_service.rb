class AppointmentRequestService
  def self.create(params)
    request = AppointmentRequest.new(params)
    ApplicationRecord.transaction do
      invalidate_previous_pending(request.guest_email, replaced_by: request)
      raise ActiveRecord::Rollback unless request.save
    end

    if request.persisted?
      log_event("appointment_request.created", request)
    else
      log_event("appointment_request.create_failed", request, errors: request.errors.full_messages)
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
    log_event("appointment_request.accepted", request)
    request
  end

  def self.reject!(request, rejection_note: nil)
    request.update!(status: :rejected, rejection_note: rejection_note)
    AppointmentRequestMailer.request_answered(request).deliver_later
    log_event("appointment_request.rejected", request, has_note: rejection_note.present?)
    request
  end

  class << self
    private

    def invalidate_previous_pending(guest_email, replaced_by:)
      AppointmentRequest.where(guest_email: guest_email, status: :pending).each do |r|
        r.update!(status: :rejected)
        AppointmentRequestMailer.request_answered(r, reason: :invalidated).deliver_later
        log_event("appointment_request.invalidated", r, replaced_by_email: replaced_by.guest_email)
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
          log_event("appointment_request.slot_taken", r, accepted_request_id: request.id)
        end
    end

    def log_event(event, request, **extra)
      Rails.logger.info({
        event: event,
        request_id: request.id,
        nutritionist_id: request.nutritionist_id,
        status: request.status,
        **extra
      })
    end
  end
end

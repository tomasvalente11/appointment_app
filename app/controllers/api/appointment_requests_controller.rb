module Api
  class AppointmentRequestsController < ApplicationController
    def index
      nutritionist = Nutritionist.find(params[:nutritionist_id])
      requests = nutritionist.appointment_requests.includes(:service).order(requested_at: :asc)

      render json: requests.map { |r| serialize_request(r) }
    end

    def create
      request = AppointmentRequestService.create(create_params)

      if request.persisted?
        render json: { id: request.id, status: request.status }, status: :created
      else
        render json: { errors: request.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def update
      request = AppointmentRequest.find(params[:id])

      unless request.nutritionist_id == update_params[:nutritionist_id].to_i
        return render json: { errors: ["Not authorized"] }, status: :forbidden
      end

      if update_params[:status] == "accepted"
        AppointmentRequestService.accept!(request)
      else
        AppointmentRequestService.reject!(request, rejection_note: update_params[:rejection_note])
      end

      render json: { id: request.id, status: request.status }
    rescue ActiveRecord::RecordInvalid => e
      render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
    end

    private

    def create_params
      params.require(:appointment_request).permit(
        :guest_email,
        :guest_name,
        :nutritionist_id,
        :requested_at,
        :service_id,
      )
    end

    def serialize_request(r)
      {
        guest_email:    r.guest_email,
        guest_name:     r.guest_name,
        id:             r.id,
        nutritionist_id: r.nutritionist_id,
        rejection_note: r.rejection_note,
        requested_at:   r.requested_at,
        service:        r.service && { location: r.service.location, name: r.service.name },
        status:         r.status,
      }
    end

    def update_params
      params.require(:appointment_request).permit(:nutritionist_id, :rejection_note, :status)
    end
  end
end

module Api
  class NutritionistsController < ApplicationController
    DEFAULT_DURATION_MIN = 60

    def available_dates
      nutritionist = Nutritionist.includes(:availability_slots).find(params[:id])

      lookahead    = Date.today + 120.days
      booked_by_date = AppointmentRequest
        .where(nutritionist_id: nutritionist.id, status: :accepted)
        .where(requested_at: Date.today.beginning_of_day..lookahead.end_of_day)
        .includes(:service)
        .group_by { |r| r.requested_at.in_time_zone.to_date }

      slots_by_wday = nutritionist.availability_slots.index_by(&:day_of_week)
      dates = upcoming_dates_with_slots(slots_by_wday, booked_by_date)
      render json: { available_dates: dates }
    end

    def available_slots
      nutritionist = Nutritionist.includes(:availability_slots, :services).find(params[:id])

      begin
        date = Date.parse(params[:date])
      rescue ArgumentError, TypeError
        return render json: { errors: ["Invalid date"] }, status: :unprocessable_entity
      end

      slot = nutritionist.availability_slots.find_by(day_of_week: date.wday)
      return render json: { slots: [] } unless slot

      duration = if params[:service_id].present?
        svc = nutritionist.services.find_by(id: params[:service_id])
        return render json: { errors: ["Service not found"] }, status: :not_found unless svc
        svc.duration
      else
        DEFAULT_DURATION_MIN
      end

      booked_ranges = booked_ranges_on(nutritionist.id, date)
      slots = slot.open_slots_on(date, duration).reject do |start_t|
        end_t = start_t + duration.minutes
        booked_ranges.any? { |r| start_t < r.last && end_t > r.first }
      end

      render json: { slots: slots.map { |t| t.strftime("%H:%M") } }
    end

    private

    def booked_ranges_on(nutritionist_id, date)
      AppointmentRequest
        .where(nutritionist_id: nutritionist_id, status: :accepted)
        .where(requested_at: date.beginning_of_day..date.end_of_day)
        .includes(:service)
        .map do |r|
          start_t = r.requested_at.in_time_zone
          start_t..(start_t + (r.service&.duration || DEFAULT_DURATION_MIN).minutes)
        end
    end

    def upcoming_dates_with_slots(slots_by_wday, booked_by_date, count: 60)
      return [] if slots_by_wday.empty?

      dates = []
      date  = Date.today
      while dates.size < count
        slot = slots_by_wday[date.wday]
        if slot
          booked_ranges = (booked_by_date[date] || []).map do |r|
            start_t = r.requested_at.in_time_zone
            start_t..(start_t + (r.service&.duration || DEFAULT_DURATION_MIN).minutes)
          end
          open = slot.open_slots_on(date, DEFAULT_DURATION_MIN).reject do |start_t|
            end_t = start_t + DEFAULT_DURATION_MIN.minutes
            booked_ranges.any? { |r| start_t < r.last && end_t > r.first }
          end
          dates << date if open.any?
        end
        date += 1.day
      end
      dates
    end
  end
end

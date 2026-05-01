class NutritionistAvailabilityController < ApplicationController
  def show
    @nutritionist = Nutritionist.includes(:availability_slots).find(params[:nutritionist_id])
    @slots_by_day = @nutritionist.availability_slots.index_by(&:day_of_week)
  end

  def update
    @nutritionist = Nutritionist.find(params[:nutritionist_id])

    (0..6).each do |day|
      day_params = availability_params[day.to_s]

      if day_params&.fetch(:active, "0") == "1"
        slot = @nutritionist.availability_slots.find_or_initialize_by(day_of_week: day)
        slot.update!(start_time: day_params[:start_time], end_time: day_params[:end_time])
      else
        @nutritionist.availability_slots.find_by(day_of_week: day)&.destroy
      end
    end

    redirect_to nutritionist_availability_path(@nutritionist), notice: "Availability updated."
  end

  private

  def availability_params
    params.require(:availability).permit(
      (0..6).map { |d| [ d.to_s, [ :active, :end_time, :start_time ] ] }.to_h
    )
  end
end

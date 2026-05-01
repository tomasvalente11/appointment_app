class AvailabilitySlot < ApplicationRecord
  DAYS = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday].freeze

  # associations
  belongs_to :nutritionist

  # validations
  validates :day_of_week, inclusion: { in: 0..6 }, uniqueness: { scope: :nutritionist_id }
  validates :end_time, :start_time, presence: true
  validate :end_time_after_start_time

  def day_name
    DAYS[day_of_week]
  end

  def open_slots_on(date, duration_minutes)
    slots = []
    current = Time.zone.local(date.year, date.month, date.day, start_time.hour, start_time.min)
    finish  = Time.zone.local(date.year, date.month, date.day, end_time.hour, end_time.min)

    while current + duration_minutes.minutes <= finish
      slots << current
      current += duration_minutes.minutes
    end

    slots
  end

  private

  def end_time_after_start_time
    return unless start_time && end_time
    errors.add(:end_time, "must be after start time") if end_time <= start_time
  end
end

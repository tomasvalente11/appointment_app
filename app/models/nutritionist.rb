class Nutritionist < ApplicationRecord
  # associations
  has_many :appointment_requests, dependent: :destroy
  has_many :availability_slots, dependent: :destroy
  has_many :services, dependent: :destroy

  # validations
  validates :name, presence: true

  # scopes
  scope :available_on, ->(date) {
    joins(:availability_slots)
      .where(availability_slots: { day_of_week: date.wday })
      .distinct
  }

  scope :nearest_to, ->(lat, lng, max_km: 100) {
    distance_sql = Nutritionist.send(:haversine_sql, lat.to_f, lng.to_f)
    joins(:services)
      .where.not(services: { latitude: nil, longitude: nil })
      .select("nutritionists.*, MIN(#{distance_sql}) AS min_distance")
      .group("nutritionists.id")
      .having("MIN(#{distance_sql}) <= #{max_km.to_f}")
      .order(Arel.sql("MIN(#{distance_sql}) ASC"))
  }

  def self.haversine_sql(lat, lng)
    <<~SQL.squish
      (12742 * asin(sqrt(
        power(sin(radians((services.latitude - #{lat}) / 2)), 2) +
        cos(radians(#{lat})) * cos(radians(services.latitude)) *
        power(sin(radians((services.longitude - #{lng}) / 2)), 2)
      )))
    SQL
  end
  private_class_method :haversine_sql

  scope :search_by_term, ->(term) {
    joins(:services)
      .where("nutritionists.name ILIKE :q OR nutritionists.bio ILIKE :q OR services.name ILIKE :q", q: "%#{term}%")
      .distinct
  }
end

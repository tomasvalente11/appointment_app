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
    dist = Arel.sql(Nutritionist.send(:haversine_sql, lat.to_f, lng.to_f))
    min_dist = Arel.sql("MIN(#{dist})")
    joins(:services)
      .where.not(services: { latitude: nil, longitude: nil })
      .select(Arel.sql("nutritionists.*, #{min_dist} AS min_distance"))
      .group("nutritionists.id")
      .having(Arel.sql("#{min_dist} <= #{max_km.to_f}"))
      .order(Arel.sql("#{min_dist} ASC"))
  }

  def self.haversine_sql(lat, lng)
    sanitize_sql_array([
      "(12742 * asin(sqrt(" \
      "power(sin(radians((services.latitude - ?) / 2)), 2) + " \
      "cos(radians(?)) * cos(radians(services.latitude)) * " \
      "power(sin(radians((services.longitude - ?) / 2)), 2))))",
      Float(lat), Float(lat), Float(lng)
    ])
  end
  private_class_method :haversine_sql

  scope :search_by_term, ->(term) {
    joins(:services)
      .where("nutritionists.name ILIKE :q OR nutritionists.bio ILIKE :q OR services.name ILIKE :q", q: "%#{term}%")
      .distinct
  }
end

class Service < ApplicationRecord
  # associations
  belongs_to :nutritionist

  # validations
  validates :duration, :location, :name, :price, presence: true

  # callbacks
  after_validation :geocode, if: :address_changed?
  geocoded_by :address
end
